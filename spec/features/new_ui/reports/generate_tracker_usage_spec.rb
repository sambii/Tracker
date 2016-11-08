# generate_tracker_usage_spec.rb
require 'spec_helper'


describe "Generate Tracker Usage Report", js:true do
  before (:each) do

    create_and_load_arabic_model_school

    @school1 = FactoryGirl.create :school, :arabic
    @teacher1 = FactoryGirl.create :teacher, school: @school1
    @subject1 = FactoryGirl.create :subject, school: @school1, subject_manager: @teacher1
    @section1_1 = FactoryGirl.create :section, subject: @subject1
    @discipline = @subject1.discipline

    load_test_section(@section1_1, @teacher1)

  end

  describe "as teacher" do
    before do
      sign_in(@teacher)
    end
    it { has_valid_tracker_usage_report(:teacher) }
  end

  describe "as school administrator" do
    before do
      @school_administrator = FactoryGirl.create :school_administrator, school: @school1
      sign_in(@school_administrator)
    end
    it { has_valid_tracker_usage_report(:school_administrator) }
  end

  describe "as researcher" do
    before do
      @researcher = FactoryGirl.create :researcher
      sign_in(@researcher)
      set_users_school(@school1)
    end
    it { has_valid_tracker_usage_report(:researcher) }
  end

  describe "as system administrator" do
    before do
      @system_administrator = FactoryGirl.create :system_administrator
      sign_in(@system_administrator)
      Rails.logger.debug("*** @school1: #{@school1.inspect}")
      set_users_school(@school1)
    end
    it { has_valid_tracker_usage_report(:system_administrator) }
  end

  describe "as student" do
    before do
      sign_in(@student)
      @err_page = "/students/#{@student.id}"
    end
    it { has_no_tracker_usage_report }
  end

  describe "as parent" do
    before do
      sign_in(@student.parent)
      @err_page = "/parents/#{@student.parent.id}"
    end
    it { has_no_tracker_usage_report }
  end

  ##################################################
  # test methods

  def has_no_tracker_usage_report
    # should not have a link to generate reports
    page.should_not have_css("#side-reports")
    page.should_not have_css("a", text: 'Generate Reports')
    # should fail when going to generate reports page directly
    visit new_generate_path
    assert_equal(@err_page, current_path)
    page.should_not have_content('Internal Server Error')
    # should fail when running attendance report directly
    visit attendance_report_attendances_path
    assert_equal(@err_page, current_path)
    within('head title') do
      page.should_not have_content('Internal Server Error')
    end
  end

  def has_valid_tracker_usage_report(role)
    page.should have_css("#side-reports a", text: 'Generate Reports')
    find("#side-reports a", text: 'Generate Reports').click
    page.should have_content('Generate Reports')
    within("#page-content") do
      within('form#new_generate') do
        page.should have_css('fieldset#ask-subjects', visible: false)
        page.should have_css('fieldset#ask-date-range', visible: false)
        page.should have_selector("select#generate-type")
        select('Tracker Usage', from: "generate-type")
        find("select#generate-type").value.should == "tracker_usage"
        find("button", text: 'Generate').click
      end
    end
    save_and_open_page
    assert_equal(attendance_report_attendances_path(), current_path)
    page.should_not have_content('Internal Server Error')

    within("#page-content") do
      within('.report-body') do
        
        page.should have_content("Attendance Report")
        within('table thead.table-title') do
          page.should have_content('ID')
          page.should have_content('Student Name')
          page.should have_content(@at_tardy.description)
          page.should have_content(@at_absent.description)
          page.should have_content('Comment')
        end



      end
    end

      # page.should_not have_content("#{@subject3.discipline.name} : #{@subject3.name}")
      # within("tbody#subj_header_#{@subject1.id}") do
      #   page.should have_content("#{@subject1.discipline.name} : #{@subject1.name}")
      #   page.should_not have_content("#{@subject2.discipline.name} : #{@subject2.name}")
      # end
      # within("tbody#subj_body_#{@subject1.id}") do
      #   within("#sect_#{@section1_1.id}") do
      #     page.should have_content("#{@teacher1.full_name}")
      #     page.should have_content("#{@section1_1.line_number}")
      #     page.should have_content("#{@section1_1.active_students.count}")
      #   end
      #   within("#sect_#{@section1_2.id}") do
      #     page.should have_content("#{@teacher1.full_name}")
      #     page.should have_content("#{@section1_2.line_number}")
      #     page.should have_content("#{@section1_2.active_students.count}")
      #   end
      #   within("#sect_#{@section1_3.id}") do
      #     page.should have_content("#{@teacher1.full_name}")
      #     page.should have_content("#{@section1_3.line_number}")
      #     page.should have_content("#{@section1_3.active_students.count}")
      #   end
      #   page.should_not have_css("#sect_#{@section2_1.id}")
      #   page.should_not have_css("#sect_#{@section2_2.id}")
      #   page.should_not have_css("#sect_#{@section2_3.id}")
      # end

      # within("tbody#subj_header_#{@subject2.id}") do
      #   page.should_not have_content("#{@subject1.discipline.name} : #{@subject1.name}")
      #   page.should have_content("#{@subject2.discipline.name} : #{@subject2.name}")
      # end
      # within("tbody#subj_body_#{@subject2.id}") do
      #   within("#sect_#{@section2_1.id}") do
      #     page.should_not have_content("#{@teacher1.full_name}")
      #     page.should have_content("#{@section2_1.line_number}")
      #     page.should have_content("#{@section2_1.active_students.count}")
      #   end
      #   within("#sect_#{@section2_2.id}") do
      #     page.should_not have_content("#{@teacher1.full_name}")
      #     page.should have_content("#{@section2_2.line_number}")
      #     page.should have_content("#{@section2_2.active_students.count}")
      #   end
      #   within("#sect_#{@section2_3.id}") do
      #     page.should_not have_content("#{@teacher1.full_name}")
      #     page.should have_content("#{@section2_3.line_number}")
      #     page.should have_content("#{@section2_3.active_students.count}")
      #   end
      #   page.should_not have_css("#sect_#{@section1_1.id}")
      #   page.should_not have_css("#sect_#{@section1_2.id}")
      #   page.should_not have_css("#sect_#{@section1_3.id}")
      # end

      # # click on right arrow should minimize subject
      # page.should have_css("tbody#subj_header_#{@subject1.id}.show-tbody-body")
      # find("a#subj_header_#{@subject1.id}_a").click
      # page.should_not have_css("tbody#subj_header_#{@subject1.id}.show-tbody-body")
      # # click on down arrow should maximize subject
      # find("a#subj_header_#{@subject1.id}_a").click
      # page.should have_css("tbody#subj_header_#{@subject1.id}.show-tbody-body")

      # # todo - click on right arrow at top of page should minimize all subjects

      # # todo - click on down arrow at top of page should maximize all subjects

    # end # within("#page-content") do

    # if (can_create)
    #   # click on add subject should show add subject popup
    #   find("a#add-subject").click
    #   within('#modal-body') do
    #     within('h3') do
    #       page.should have_content('Create Subject')
    #     end
    #     page.should have_content(@school1.name)
    #     page.should have_selector("#subject-discipline-id")
    #     # page.all('select#subject-discipline-id option').map(&:value).should == ['', '1', '2', '3' ]
    #     find("select#subject-discipline-id").value.should == ''
    #     select(@discipline.name, from: "subject-discipline-id")
    #     page.fill_in 'subject-name', :with => 'New Subject Name'
    #     select(@teacher1.full_name, from: 'subject_subject_manager_id')
    #     page.click_button('Save')
    #   end
    #   # save should go back to subject / section listing
    #   within('#page-content') do
    #     page.should have_content("#{@discipline.name} : New Subject Name")
    #   end

    #   # click on edit subject should show edit subject popup
    #   find("a[data-url='/subjects/#{@subject1.id}/edit.js']").click
    #   within('#modal-body') do
    #     within('h3') do
    #       page.should have_content("Edit Subject - #{@subject1.name}")
    #     end
    #     page.should have_content(@school1.name)
    #     page.should have_selector("#subject-discipline-id")
    #     # page.all('select#subject-discipline-id option').map(&:value).should == ['', '1', '2', '3' ]
    #     find("select#subject-discipline-id").value.should == "#{@discipline.id}"
    #     select(@discipline2.name, from: "subject-discipline-id")
    #     page.should have_selector("#subject-name", value: "#{@subject1.name}")
    #     # todo - checks for duplicate subject name within school - is this allowed?
    #     page.fill_in 'subject-name', :with => 'Changed Subject Name'
    #     find("#subject_subject_manager_id").value.should == "#{@teacher1.id}"
    #     select(@teacher2.full_name, from: 'subject_subject_manager_id')
    #     page.click_button('Save')
    #   end
    #   # save should go back to subject / section listing
    #   within('#page-content') do
    #     page.should have_content("#{@discipline2.name} : Changed Subject Name")
    #   end

    #   # click on edit section should show edit section popup
    #   find("a[data-url='/sections/#{@section1_2.id}/edit.js']").click
    #   within('#modal-body') do
    #     within('h3') do
    #       page.should have_content("Edit Section: #{@section1_2.name} - #{@section1_2.line_number}")
    #     end
    #     within('#section_line_number') do
    #       page.should_not have_content(@section1_2.subject.name)
    #     end
    #     page.should have_selector("#section_line_number", value: "#{@section1_2.line_number}")
    #     page.fill_in 'section_line_number', :with => 'Changed Section ID'
    #     within('#section_message') do
    #       page.should have_content(@section1_2.message)
    #     end
    #     page.should have_selector("#section_school_year_id", value: "#{@section1_2.school_year.name}")
    #     page.click_button('Save')
    #   end
    #   # save should go back to section listing
    #   page.should have_selector("#sect_#{@section1_2.id}")
    #   within("#sect_#{@section1_2.id}") do
    #     page.should have_selector(".sect-section", value: "Changed Section ID")
    #   end

    #   # click on add section should show add section popup
    #   # Rails.logger.debug("*** subj_header_#{@section1_2.subject.id}")
    #   # find("subj_header_#{@section1_2.subject.id} a.add-section").click
    #   # within('#modal-body') do
    #   #   within('h3') do
    #   #     page.should have_content("Add Section")
    #   #   end
    #   #   # within('#section_line_number') do
    #   #   #   page.should_not have_content(@section1_2.subject.name)
    #   #   # end
    #   #   # page.should have_selector("#section_line_number", value: "#{@section1_2.line_number}")
    #   #   # page.fill_in 'section_line_number', :with => 'Changed Section ID'
    #   #   # within('#section_message') do
    #   #   #   page.should have_content(@section1_2.message)
    #   #   # end
    #   #   # page.should have_selector("#section_school_year_id", value: "#{@section1_2.school_year.name}")
    #   #   # page.click_button('Save')
    #   # end

    #   # # save should go back to section listing

    # end

  end # def has_valid_attendance_report


end
