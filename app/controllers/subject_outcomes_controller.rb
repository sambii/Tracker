# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class SubjectOutcomesController < ApplicationController

  include SubjectOutcomesHelper

  def index
    #
    # todo - remove this code - dead code - uses with_permissions_to from declarative_authorization gem
    @subject_outcomes = SubjectOutcome.with_permissions_to :read
  end

  def new
    @subject_outcome = SubjectOutcome.new
    @subjects = Subject.all
  end

  def create
    @subject_outcome = SubjectOutcome.new(params[:subject_outcome])
    @subjects = Subject.all #with_permissions_to(:manage_subject_outcomes)
    respond_to do |format|
      if @subject_outcome.save
        format.html { redirect_to new_section_outcome_path(:section_id => params[:section_id]) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  def edit
    @subject_outcome = SubjectOutcome.find_by_id(params[:id])

    respond_to do |format|
      format.html
    end
  end

  def update
    @subject_outcome = SubjectOutcome.find_by_id(params[:id])

    respond_to do |format|
      if @subject_outcome.update_attributes(params[:subject_outcome])
        format.html { redirect_to session[:return_to], :notice => 'Learning Outcome was successfully updated.' }
      else
        format.html { render :action => :edit }
      end
    end
  end


  # new UI, upload LOs from curriculum spreadsheet to Model School (for new year rollover)
  # new UI HTML post method
  # Bulk Upload LOs file
  # stage 2 - reads csv file in and errors found within spreadsheet
  # stage 3 - reads csv file in and errors found against database
  # stage 4 - reads csv file and performs model validation of each record
  # stage 5 - updates records within a transaction - can upload again if errors
  # see app/helpers/users_helper.rb for helper functions
  def upload_lo_file
    authorize! :manage, :all # only system admins
    # @preview = true if params['preview']
    first_display = (request.method == 'GET' && params['utf8'].blank?)
    Rails.logger.debug("*** first_display: #{first_display}")
    @stage = 1
    Rails.logger.debug("*** SchoolsController.upload_LO_file started")
    @errors = Hash.new
    @error_list = Hash.new
    @records = Array.new

    match_model_schools = School.where(acronym: 'MOD')
    if match_model_schools.count == 1
      @school = match_model_schools.first
      if @school.school_year_id.blank?
        @errors[:base] = 'ERROR: Missing school year for Model School'
      else
        @school_year = @school.school_year
        session[:school_context] = @school.id
        set_current_school
      end
      if !@school.has_flag?(School::GRADE_IN_SUBJECT_NAME)
        @errors[:base] = 'Error: Bulk Upload is for schools with grade in subject name only.'
      end
    else
      Rails.logger.error("Error: Missing Model School")
    end

    @subjects = Subject.where(school_id: @school.id)
    @subject = nil

    # if only processing one subject, look up the subject by selected subject ID
    if params[:subject_id].present?
      match_subjects = Subject.where(id: params[:subject_id])
      @match_subject = nil
      @subject_id = ''
      if match_subjects.count == 0
        @errors[:subject] = "Error: Cannot find subject"
      else
        @match_subject = match_subjects.first
        @subject_id = @match_subject.present? ? @match_subject.id : ''
      end
    end
    Rails.logger.debug("*** @match_subject: #{@match_subject} = #{@match_subject.name.unpack('U' * @match_subject.name.length)}") if @match_subject

    if @errors.count > 0
      Rails.logger.debug("*** @errors: #{@errors.inspect}")
      # don't process, error
    elsif params['file'].blank?
      if !first_display
        @errors[:filename] = "Error: Missing Curriculum (LOs) Upload File."
      end
    else

      # stage 2
      @stage = 2
      Rails.logger.debug("*** Stage: #{@stage}")
      @subject_ids = Hash.new
      @subject_names = Hash.new
      Rails.logger.debug("*** create subject names hash")
      @subjects.each do |s|
        @subject_ids[s.id] = s if !@subject_id.present? || (@subject_id.present? && @subject_id == s.id) # IDs of all subjects to process
        @subject_names[s.name] = s # all subject names
      end
      # no initial errors, process file
      @filename = params['file'].original_filename
      # @errors[:filename] = 'Choose file again to rerun'
      # note: 'headers: true' uses column header as the key for the name (and hash key)
      ix = 0
      CSV.foreach(params['file'].path, headers: true) do |row|
        rhash = validate_csv_fields(row.to_hash.with_indifferent_access, @subject_names)
        rhash[COL_REC_ID] = ix
        if rhash[COL_ERROR]
          @errors[:base] = 'Errors exist - see below:' if !rhash[COL_EMPTY]
        end
        check_subject = "#{rhash[COL_COURSE]} #{rhash[COL_GRADE]}"
        if @match_subject.blank?
          ix += 1
          matched_subject = false
          # processing all subjects in file
          Rails.logger.debug("*** Add @records item: #{rhash.inspect}")
          Rails.logger.debug("*** match (any) subject: #{matched_subject} for #{check_subject} = #{check_subject.unpack('U' * check_subject.length)}")
          @records << rhash if !rhash[COL_EMPTY]
        else
          matched_subject = (@match_subject.name == check_subject)
          if matched_subject
            ix += 1
            Rails.logger.debug("*** Add @records item: #{rhash.inspect}")
            Rails.logger.debug("*** match subject: #{matched_subject} for #{check_subject} = #{check_subject.unpack('U' * check_subject.length)}")
            @records << rhash if !rhash[COL_EMPTY]
          end
        end
      end  # end CSV.foreach

      # check for file duplicate LO Codes
      dup_lo_code_checked = validate_dup_lo_codes(@records)
      @error_list = dup_lo_code_checked[:error_list]
      Rails.logger.debug("*** @error_list: #{@error_list.inspect}")
      @records = dup_lo_code_checked[:records]
      Rails.logger.debug("*** records count: #{@records.count}")
      @errors[:base] = 'Errors exist - see below!!!:' if dup_lo_code_checked[:abort] || @error_list.length > 0

      # check for file duplicate LO Descriptions
      dup_lo_descs_checked = validate_dup_lo_descs(@records)
      @error_list2 = dup_lo_descs_checked[:error_list]
      Rails.logger.debug("*** @error_list2: #{@error_list2.inspect}")
      @records = dup_lo_descs_checked[:records]
      Rails.logger.debug("*** records count: #{@records.count}")
      @errors[:base] = 'Errors exist - see below!!!:' if dup_lo_descs_checked[:abort] || @error_list2.length > 0

      # validate records

      # stage 3
      @stage = 3
      Rails.logger.debug("*** Stage: #{@stage}")


      # create an hash by lo_codes for matching database to upload file.
      new_lo_codes_h = Hash.new
      new_lo_names_h = Hash.new
      @records.each_with_index do |rx, ix|
        rec  = Hash.new
        rec[COL_REC_ID] = rx[COL_REC_ID]
        rec[COL_COURSE] = rx[COL_COURSE]
        rec[COL_GRADE] = rx[COL_GRADE]
        rec[COL_MP_BITMAP] = rx[COL_MP_BITMAP]
        rec[COL_OUTCOME_CODE] = rx[COL_OUTCOME_CODE]
        rec[COL_OUTCOME_NAME] = rx[COL_OUTCOME_NAME]
        rec[PARAM_ID] = rx[PARAM_ID]
        rec[PARAM_ACTION] =  rx[PARAM_ACTION]

        shortened_name = (rx[COL_OUTCOME_NAME].present? ? rx[COL_OUTCOME_NAME].truncate(50, omission: '...') : '')
        rx[COL_SHORTENED_NAME] = shortened_name
        # new_lo_codes_by_lo << { lo_code: rx[COL_OUTCOME_CODE], ix: ix }
        # new_lo_codes_by_name << { name: shortened_name, ix: ix }
        new_lo_codes_h[rx[COL_OUTCOME_CODE]] = rec
        Rails.logger.debug("*** @record[#{ix}]: [#{rx.inspect}")
        # Rails.logger.debug("*** new_lo_codes[#{rx[COL_OUTCOME_CODE]}] = #{rx[COL_REC_ID]}")
        new_lo_names_h[shortened_name] = rec
      end

      # get the subject outcomes from the database for all subjects to process
      old_los_by_lo = Hash.new
      # optimize active record for one db call
      db_active = 0
      db_deact = 0
      SubjectOutcome.where(subject_id: @subject_ids.map{|k,v| k}).each do |so|
        subject_name = @subject_ids[so.subject_id].name
        # is matched_subject if we are processing all subjects or if current subject matches the selected subject
        matched_subject = @match_subject.blank? || @match_subject.name == subject_name
        if matched_subject # only add record if all subjects or the matching selected subject
          Rails.logger.debug("*** Subject Outcome: #{so.inspect}")
          old_los_by_lo[so.lo_code] = {
            db_id: so.id,
            subject_name: subject_name,
            subject_id: so.subject_id,
            lo_code: so.lo_code,
            name: so.name,
            short_desc: so.shortened_description,
            desc: so.description,
            grade: so.subject.grade_from_subject_name,
            mp: SubjectOutcome.get_bitmask_string(so.marking_period),
            active: so.active
          } 
          if so.active
            db_active += 1
          else
            db_deact += 1
          end
        end
      end

      @match_level = 6
      @pairs = Array.new
      @pairs_filtered = Array.new

      # process matches
      # new_lo_codes.product(old_lo_codes).each.map { |p| p if }
      # process matches
      @match_count = 0
      @mismatch_count = 0
      @add_count = 0
      @not_add_count = 0 # temporary coding to allow add only mode till programming completed.
      iy = 0
      # process the database records (for all or selected subject)
      old_los_by_lo.each do |rk, old_rec|
        Rails.logger.debug("*** rk: #{rk}, old_rec: #{old_rec}")
        # lookup the database lo_code in the new curriculum
        new_match = new_lo_codes_h[rk]
        if new_match
          # fix for when database has no matching code in the input file
          Rails.logger.debug("*** new_match true")
          matching_pairs= lo_match_old_new(old_rec, (new_match ||= {}), @match_level)
          # @records3 << [old_rec, new_match, matches] # output matches for matching report
          @pairs_filtered.concat(matching_pairs) # @record3 appended with matching update page pairs for this old record

        end
      end

      @pair_count = 0

      # # post process of matching
      # @pairs.each do |rec|
      #   old_rec_to_match = rec[0]
      #   matched_new_rec = rec[1]
      #   matched_weights = rec[2]

      #   if matched_weights[:total_match] < @match_level
      #     # ignore this match, it is below the match_level
      #   else
      #     @pairs_filtered << rec
      #     @pair_count += 1
      #     # code to mark new uploaded records as matched by lo_code
      #     Rails.logger.debug("*** matched_new_rec: #{matched_new_rec.inspect}")
      #     if matched_new_rec && matched_new_rec[COL_REC_ID]
      #       matched_rec_num = matched_new_rec[COL_REC_ID].to_i
      #       Rails.logger.debug("*** matched_rec_num: #{matched_rec_num}")
      #       @records[matched_new_rec[COL_REC_ID].to_i][COL_STATE] = 'match_lo_code'
      #     else
      #       Rails.logger.error("Error: matching new record problem.")
      #       raise("Error: matching new record problem.")
      #     end

      #     # # determine if all actions have been determined (no mismatch actions)
      #     # @mismatch_count += 1 if old_rec_to_match[PARAM_ACTION] == 'Mismatch' || (matched_new_rec && matched_new_rec[PARAM_ACTION] == 'Mismatch')
      #     # @match_count += 1 if matched_weights[:total_match] == @match_level

      #     # # determine if any action other than Add has been used (Add only till programming done)
      #     # @not_add_count += 1 if !['', 'Add'].include?(old_rec_to_match[PARAM_ACTION])
      #   end
      #   # code to mark original records as matched to curriculum by lo_code
      # end

      # output any unmatched new records
      @records.each_with_index do |rx, ix|
        Rails.logger.debug("*** Check matching of rx #{ix}: #{rx.inspect}")
        if rx[COL_STATE].blank?
          Rails.logger.debug("*** Add @record #{ix}: #{rx.inspect}")
          add_pair = lo_match_old_new({}, rx, 0)
          @pairs.concat(add_pair)
          @pairs_filtered.concat(add_pair)
        end
      end

      Rails.logger.debug("*** records count: #{@records.count}")
      Rails.logger.debug("*** pairs count: #{@pairs.count}")
      Rails.logger.debug("*** pairs_filtered count: #{@pairs_filtered.count}")
      Rails.logger.debug("*** match_count : #{@match_count}")
      Rails.logger.debug("*** mismatch_count : #{@mismatch_count}")
      Rails.logger.debug("*** not_add_count : #{@not_add_count}")
      Rails.logger.debug("*** add_count : #{@add_count}")
      Rails.logger.debug("*** db_active count: #{db_active}")
      Rails.logger.debug("*** db_deact count: #{db_deact}")

    end # end stage 1-4

    if @errors.count == 0 && @error_list.length == 0 && !first_display

      # stage 5
      @stage = 5
    end

    Rails.logger.debug("*** Final Stage: #{@stage}")

    Rails.logger.debug("*** @errors: #{@errors.inspect}")
    @any_errors = @errors.count > 0 || @error_list.count > 0

    @rollback = false

    respond_to do |format|
      if @stage == 1 || @any_errors
        format.html
      else
        format.html { render :action => "lo_matching" }
      end
    end

  end # upload_LO_file

  # new UI, matching process for Bulk LO Upload
  # new UI HTML post method
  def lo_matching
    authorize! :manage, :all # only system admins
    Rails.logger.debug("*** SchoolsController.lo_matching started")
    begin
      @stage = 1
      step = 0
      @records = Array.new
      @pairs = Array.new
      @pairs_filtered = Array.new
      @errors = Hash.new

      @school = School.find(params['school_id'])
      raise('Invalid school - not model school') if @school.acronym != 'MOD'

      @subjects = Subject.where(school_id: @school.id)

      # if only processing one subject, look up the subject by selected subject ID
      @match_subject = nil
      if params[:subject_id].present?
        match_subjects = Subject.where(id: params[:subject_id])
        if match_subjects.count == 0
          @errors[:subject] = "Error: Cannot find subject"
        end
        @match_subject = match_subjects.first
        @subject_id = @match_subject.present? ? @match_subject.id : ''
      else
        @subject_id = ''
      end
      Rails.logger.debug("*** @match_subject: #{@match_subject} = #{@match_subject.name.unpack('U' * @match_subject.name.length)}") if @match_subject

      Rails.logger.debug("*** create subject hashes")
      @subject_ids = Hash.new
      @subject_names = Hash.new
      @subjects.each do |s|
        @subject_ids[s.id] = s if !@subject_id.present? || (@subject_id.present? && @subject_id == s.id) # IDs of all subjects to process
        @subject_names[s.name] = s
      end

      step = 1
      # get the subject outcomes from the database for all subjects to process
      old_los_by_lo = Hash.new
      # optimize active record for one db call
      db_active = 0
      db_deact = 0
      SubjectOutcome.where(subject_id: @subject_ids.map{|k,v| k}).each do |so|
        subject_name = @subject_ids[so.subject_id].name
        # is matched_subject if we are processing all subjects or if current subject matches the selected subject
        matched_subject = @match_subject.blank? || @match_subject.name == subject_name
        if matched_subject # only add record if all subjects or the matching selected subject
          Rails.logger.debug("*** Subject Outcome: #{so.inspect}")
          old_los_by_lo[so.lo_code] = {
            db_id: so.id,
            subject_name: subject_name,
            subject_id: so.subject_id,
            lo_code: so.lo_code,
            name: so.name,
            short_desc: so.shortened_description,
            desc: so.description,
            grade: so.subject.grade_from_subject_name,
            mp: SubjectOutcome.get_bitmask_string(so.marking_period),
            active: so.active
          } 
          if so.active
            db_active += 1
          else
            db_deact += 1
          end
        end
      end

      # process request parameters
      # recreate uploaded records to process
      # Perform any actions required for this stage of the matching process
      step = 2
      @mismatch_count = 0
      @not_add_count = 0 # temporary coding to allow add only mode till programming completed.
      old_rec_actions = []
      params['pair'].each do |p|
        pold = p[1]['o']
        pold ||= {}
        pnew = p[1]['n']
        pnew ||= {}

        # recreate upload records (with only fields needed)
        if pnew.length > 0 && pnew[COL_REC_ID]
          rec  = Hash.new
          rec[COL_REC_ID] = pnew[COL_REC_ID]
          rec[COL_COURSE] = pnew[COL_COURSE]
          rec[COL_COURSE_ID] = pnew[COL_COURSE_ID]
          rec[COL_GRADE] = pnew[COL_GRADE]
          rec[COL_MP_BITMAP] = pnew[COL_MP_BITMAP]
          rec[COL_OUTCOME_CODE] = pnew[COL_OUTCOME_CODE]
          rec[COL_OUTCOME_NAME] = pnew[COL_OUTCOME_NAME]
          rec[PARAM_ID] = pnew[PARAM_ID]
          rec[PARAM_ACTION] =  pnew[PARAM_ACTION]
          @records << rec
        end

        # save off old rec if there is an action to do on it
        if pold.length > 0 && pold[PARAM_ACTION] && !['Mismatch', ''].include?(pold[PARAM_ACTION])
          old_rec_actions << pold
        end

        # determine if all actions have been determined (no mismatch actions)
        if pold[PARAM_ACTION] == 'Mismatch' || pnew[PARAM_ACTION] == 'Mismatch'
          @mismatch_count += 1
        end

        # determine if any action other than Add has been used (Add only till programming done)
        @not_add_count += 1 if !['', 'Add'].include?(pold[PARAM_ACTION]) || !['', 'Add'].include?(pnew[PARAM_ACTION])

      end

      step = 3
      new_lo_codes_h = Hash.new
      new_lo_names_h = Hash.new
      @records.each do |rx|
        shortened_name = (rx[COL_OUTCOME_NAME].present? ? rx[COL_OUTCOME_NAME].truncate(50, omission: '...') : '')
        new_lo_codes_h[rx[COL_OUTCOME_CODE]] = rx
        new_lo_names_h[shortened_name] = rx
      end

      # Rails.logger.debug("*** new_lo_codes_h: #{new_lo_codes_h.inspect}")
      # Rails.logger.debug("*** new_lo_names_h: #{new_lo_names_h.inspect}")
      step = 41

      # process matches
      # new_lo_codes.product(old_lo_codes).each.map { |p| p if }
      # process matches
      @match_level = params[:match_level].present? ? params[:match_level].to_i : 6
      @match_count = 0
      @mismatch_count = 0
      @add_count = 0
      @not_add_count = 0 # temporary coding to allow add only mode till programming completed.
      iy = 0
      # process the database records (for all or selected subject)
      step = 42
      old_los_by_lo.each do |rk, old_rec|
        Rails.logger.debug("*** rk: #{rk}, old_rec: #{old_rec}")
        # lookup the database lo_code in the new curriculum
        new_match = new_lo_codes_h[rk]
        if new_match
          # fix for when database has no matching code in the input file
          Rails.logger.debug("*** new_match true")
          matching_pairs= lo_match_old_new(old_rec, (new_match ||= {}), @match_level)
          Rails.logger.debug("*** matching_pairs: #{matching_pairs}")
          @pairs_filtered.concat(matching_pairs) # @record3 appended with matching update page pairs for this old record
        end
      end

      # # post process of matching (including filtering @pairs to @pairs_filtered)
      # @pairs.each do |rec|
      #   Rails.logger.debug("*** rec: #{rec.inspect}")
      #   old_rec_to_match = rec[0]
      #   matched_new_rec = rec[1]
      #   matched_weights = rec[2]

      #   if matched_weights[:total_match] < @match_level
      #     # ignore this match, it is below the match_level
      #   else
      #     @pairs_filtered << rec
      #     # code to mark new uploaded records as matched by lo_code
      #     Rails.logger.debug("*** matched_new_rec: #{matched_new_rec.inspect}")
      #     if matched_new_rec && matched_new_rec[COL_REC_ID]
      #       matched_rec_num = matched_new_rec[COL_REC_ID].to_i
      #       Rails.logger.debug("*** matched_rec_num: #{matched_rec_num}")
      #       @records[matched_new_rec[COL_REC_ID].to_i][COL_STATE] = 'match_lo_code'
      #     else
      #       Rails.logger.error("Error: matching new record problem.")
      #       raise("Error: matching new record problem.")
      #     end

      #     # # determine if all actions have been determined (no mismatch actions)
      #     # @mismatch_count += 1 if old_rec_to_match[PARAM_ACTION] == 'Mismatch' || (matched_new_rec && matched_new_rec[PARAM_ACTION] == 'Mismatch')
      #     # @match_count += 1 if matched_weights[:total_match] == @match_level

      #     # # determine if any action other than Add has been used (Add only till programming done)
      #     # @not_add_count += 1 if !['', 'Add'].include?(old_rec_to_match[PARAM_ACTION])
      #   end
      # end

      step = 5
      # output any unmatched new records
      @records.each_with_index do |rx, ix|
        Rails.logger.debug("*** Check matching of rx #{ix}: #{rx.inspect}")
        if rx[COL_STATE].blank?
          Rails.logger.debug("*** Add @record #{ix}: #{rx.inspect}")
          add_pair = lo_match_old_new({}, rx, 0)
          Rails.logger.debug("*** Add pair")
          @pairs.concat(add_pair)
          @pairs_filtered.concat(add_pair)
        end
      end

      Rails.logger.debug("*** @mismatch_count: #{@mismatch_count}")
      Rails.logger.debug("*** submit_action: #{params[:submit_action]}")
      Rails.logger.debug("*** Update? : #{@mismatch_count == 0 && params[:submit_action] == 'save_all'}")

      Rails.logger.debug("*** records count: #{@records.count}")
      Rails.logger.debug("*** pairs count: #{@pairs.count}")
      Rails.logger.debug("*** pairs_filtered count: #{@pairs_filtered.count}")
      Rails.logger.debug("*** match_count : #{@match_count}")
      Rails.logger.debug("*** mismatch_count : #{@mismatch_count}")
      Rails.logger.debug("*** not_add_count : #{@not_add_count}")
      Rails.logger.debug("*** add_count : #{@add_count}")


      step = 6
      action_count = 0
      @records4 = []
      if @mismatch_count == 0 && params[:submit_action] == 'save_all'
        ActiveRecord::Base.transaction do
          old_rec_actions.each do |rec|
            # Rails.logger.debug("*** old rec: #{rec}")
            case rec[PARAM_ACTION]
            when 'Remove'
              so = SubjectOutcome.find(rec[COL_REC_ID])
              so.active = false
              so.save!
              action_count += 1
              action = 'Removed'
              @records4 << [so, 'Removed']
            when 'Restore'
              so = SubjectOutcome.find(rec[COL_REC_ID])
              so.active = true
              so.save!
              action_count += 1
              action = 'Restored'
              @records4 << [so, 'Restored']
            when ''
              # ignore
              # Rails.logger.debug("*** 'ignore' action")
            when 'Mismatch'
              raise("Attempt to update with Mismatch - item #{action_count+1}")
            else
              raise("Invalid subject outcome action - item #{action_count+1}")
            end

          end
          @records.each do |rec|
            # Rails.logger.debug("*** new rec: #{rec}")
            case rec[PARAM_ACTION]
            when 'Add'
              so = SubjectOutcome.new
              so.lo_code = rec[COL_OUTCOME_CODE]
              so.description = rec[COL_OUTCOME_NAME]
              so.subject_id = rec[COL_COURSE_ID].to_i
              so.marking_period = rec[COL_MP_BITMAP]
              so.save!
              action_count += 1
              action = 'Added'
              @records4 << [so, 'Added']
            when ''
              # ignore
              # Rails.logger.debug("*** 'ignore' action")
            when 'Mismatch'
              raise("Attempt to update with Mismatch - item #{action_count+1}")
            else
              raise("Invalid subject outcome action - item #{action_count+1}")
            end

          end
          # raise "Successful Test cancelled" if action_count > 0
        end # transaction
        @stage = 9
      else
        # @errors[:base] =  'Invalid Upload (only adds allowed) - Not Saved'
        @stage = 5
      end # if update

    rescue => e
      msg_str = "ERROR: lo_matching Exception at step #{step} - #{e.message}"
      @errors[:base] = append_with_comma(@errors[:base], msg_str)
      Rails.logger.error(msg_str)
      flash.now[:alert] = msg_str
      @stage = 5
    end

    step = 7
    respond_to do |format|
      Rails.logger.debug("@stage: #{@stage}")
      if @errors.count > 0
        flash[:alert] = (@errors[:base].present?) ? @errors[:base] : 'Errors'
      end
      if @stage == 9
        format.html { render :action => "lo_matching_update" }
      else
        format.html
      end
    end

  end


  # def lo_matching_update
  # this page is rendered from lo_matching action
  # end

  private

end
