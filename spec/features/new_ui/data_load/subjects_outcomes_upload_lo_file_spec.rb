# subject_outcomes_upload_lo_file_spec.rb
require 'spec_helper'


describe "Subject Outcomes Bulk Upload LOs", js:true do
  before (:each) do

    create_and_load_arabic_model_school

    # two subjects in @school1
    @section1_1 = FactoryGirl.create :section
    @subject1 = @section1_1.subject
    @school1 = @section1_1.school
    @teacher1 = @subject1.subject_manager
    @discipline = @subject1.discipline

    load_test_section(@section1_1, @teacher1)

    @section1_2 = FactoryGirl.create :section, subject: @subject1
    ta1 = FactoryGirl.create :teaching_assignment, teacher: @teacher1, section: @section1_2
    @section1_3 = FactoryGirl.create :section, subject: @subject1
    ta2 = FactoryGirl.create :teaching_assignment, teacher: @teacher1, section: @section1_3

    @subject2 = FactoryGirl.create :subject, subject_manager: @teacher1
    @section2_1 = FactoryGirl.create :section, subject: @subject2
    @section2_2 = FactoryGirl.create :section, subject: @subject2
    @section2_3 = FactoryGirl.create :section, subject: @subject2
    @discipline2 = @subject2.discipline

  end

  describe "as teacher" do
    before do
      sign_in(@teacher1)
    end
    it { cannot_bulk_upload_los }
  end

  describe "as school administrator" do
    before do
      @school_administrator = FactoryGirl.create :school_administrator, school: @school1
      sign_in(@school_administrator)
    end
    it { cannot_bulk_upload_los }
  end

  describe "as researcher" do
    before do
      @researcher = FactoryGirl.create :researcher
      sign_in(@researcher)
      set_users_school(@school1)
    end
    it { cannot_bulk_upload_los }
  end

  describe "as system administrator" do
    before do
      @system_administrator = FactoryGirl.create :system_administrator
      sign_in(@system_administrator)
      set_users_school(@school1)
    end
    it { bulk_upload_all_same }
    it { bulk_upload_art_same }
    it { bulk_upload_advisory_add }
    it { bulk_upload_art_mismatches }
    it { bulk_upload_all_mismatches }
  end

  describe "as student" do
    before do
      sign_in(@student)
    end
    it { cannot_bulk_upload_los }
  end

  describe "as parent" do
    before do
      sign_in(@student.parent)
    end
    it { cannot_bulk_upload_los }
  end

  ##################################################
  # test methods

  def cannot_bulk_upload_los
    visit upload_lo_file_subject_outcomes_path()
    assert_not_equal("/subject_outcomes/upload_lo_file", current_path)
    # page.should have_content('Upload Curriculum / LOs File')
  end

  # test for all subjects bulk upload of Learning Outcomes into Model School
  # no mismatches (only adds) - can update all learning outcomes immediately without matching
  def bulk_upload_all_same
    visit upload_lo_file_subject_outcomes_path
    within("#page-content") do
      assert_equal("/subject_outcomes/upload_lo_file", current_path)
      page.should have_content('Upload Learning Outcomes from Curriculum')
      within("#ask-filename") do
        page.attach_file('file', Rails.root.join('spec/fixtures/files/bulk_upload_los_rspec_initial.csv'))
        page.should_not have_content("Error: Missing Curriculum (LOs) Upload File.")
      end
      find('#upload').click
      # if no errors, then save button should be showing
      page.should have_css("#save")
      page.should have_content('Match Old LOs to New LOs')
      within("#old-lo-count") do
        page.should have_content('38')
      end
      within("#new-lo-count") do
        page.should have_content('38')
      end
      within("#add-count") do
        page.should have_content('0')
      end
      within("#do-nothing-count") do
        page.should have_content('38')
      end
      within("#reactivated-count") do
        page.should have_content('0')
      end
      within("#deactivated-count") do
        page.should have_content('0')
      end
      within("#error-count") do
        page.should have_content('0')
      end
      page.should have_button("SAVE ALL")
      find('#save_all').click
    end # within #page-content
  end # def bulk_upload_all_matching

  # test for single subject bulk upload of Learning Outcomes into Model School
  def bulk_upload_art_same
    visit upload_lo_file_subject_outcomes_path
    within("#page-content") do
      assert_equal("/subject_outcomes/upload_lo_file", current_path)
      page.should have_content('Upload Learning Outcomes from Curriculum')
      within("#ask-filename") do
        page.attach_file('file', Rails.root.join('spec/fixtures/files/bulk_upload_los_rspec_initial.csv'))
        page.should_not have_content("Error: Missing Curriculum (LOs) Upload File.")
        select('Art 1', from: "subject_id")
      end
      find('#upload').click
      # if no errors, then save button should be showing
      page.should have_css("#save")
      page.should have_content('Match Old LOs to New LOs')
      within("#old-lo-count") do
        page.should have_content('4')
      end
      within("#new-lo-count") do
        page.should have_content('4')
      end
      within("#add-count") do
        page.should have_content('0')
      end
      page.should have_button("SAVE ALL")
      find('#save_all').click
    end # within #page-content
  end # def bulk_upload_art_matching


  # test for single subject bulk upload of Learning Outcomes into Model School
  def bulk_upload_advisory_add
    visit upload_lo_file_subject_outcomes_path
    within("#page-content") do
      assert_equal("/subject_outcomes/upload_lo_file", current_path)
      page.should have_content('Upload Learning Outcomes from Curriculum')
      within("#ask-filename") do
        page.attach_file('file', Rails.root.join('spec/fixtures/files/bulk_upload_los_rspec_updates.csv'))
        page.should_not have_content("Error: Missing Curriculum (LOs) Upload File.")
        select('Advisory 1', from: "subject_id")
      end
      find('#upload').click
      # if no errors, then save button should be showing
      page.should have_css("#save")
      page.should have_content('Match Old LOs to New LOs')
      within("#old-lo-count") do
        page.should have_content('1')
      end
      within("#new-lo-count") do
        page.should have_content('2')
      end
      within("#add-count") do
        page.should have_content('1')
      end
      page.should have_button("SAVE ALL")
      find('#save_all').click
    end # within #page-content
  end # def bulk_upload_art_matching

  # test for single subject bulk upload of Learning Outcomes into Model School
  def bulk_upload_art_mismatches
    visit upload_lo_file_subject_outcomes_path
    within("#page-content") do
      assert_equal("/subject_outcomes/upload_lo_file", current_path)
      page.should have_content('Upload Learning Outcomes from Curriculum')
      page.should have_content('Upload Curriculum / LOs File')
      within("#ask-filename") do
        page.attach_file('file', Rails.root.join('spec/fixtures/files/bulk_upload_los_rspec_updates.csv'))
        page.should_not have_content("Error: Missing Curriculum (LOs) Upload File.")
        select('Art 2', from: "subject_id")
      end
      find('#upload').click
      page.should have_content('Match Old LOs to New LOs')
      within("#old-lo-count") do
        page.should have_content('4')
      end
      within("#new-lo-count") do
        page.should have_content('4')
      end
      within("#add-count") do
        page.should have_content('2')
      end
      within("#do-nothing-count") do
        page.should have_content('2')
      end
      # errors - save button should be showing
      page.should_not have_css("#save_all")
      page.should_not have_button("SAVE ALL")
      # find('#save_all').click
    end # within #page-content
  end # def bulk_upload_art_matching

  # test for all subjects bulk upload of Learning Outcomes into Model School
  # some mismatches (deactivates, reactivates or changes) - requires subject by subject matching
  def bulk_upload_all_mismatches
    visit upload_lo_file_subject_outcomes_path
    within("#page-content") do
      assert_equal("/subject_outcomes/upload_lo_file", current_path)
      page.should have_content('Upload Learning Outcomes from Curriculum')
      within("#ask-filename") do
        page.attach_file('file', Rails.root.join('spec/fixtures/files/bulk_upload_los_rspec_updates.csv'))
        page.should_not have_content("Error: Missing Curriculum (LOs) Upload File.")
      end
      find('#upload').click
      # sleep 10
      # save_and_open_page

      assert_equal("/subject_outcomes/upload_lo_file", current_path)
      page.should have_content('Match Old LOs to New LOs')
      within('thead.table-title') do
        page.should have_content("Processing #{@subj_art_1.name} of All Subjects")
      end
      # confirm current subject los are displayed and others are not
      within('form table') do
        page.should_not have_content("AD.1.01")
        page.should_not have_content("MA.1.12")
      end

      within("tr[data-displayed-pair='pair_#{@subj_art_1.id}_0_#{@so_at_1_01.id}']") do
        page.should have_content("AT.1.01")
        page.should have_content("==")
        page.should have_css("input#selections_0_#{@so_at_1_01.id}")
        find("input#selections_0_#{@so_at_1_01.id}").should be_checked
      end
      within("tr[data-displayed-pair='pair_#{@subj_art_1.id}_1_#{@so_at_1_02.id}']") do
        page.should have_content("AT.1.02")
        page.should have_content("==")
        page.should have_css("input#selections_1_#{@so_at_1_02.id}")
        find("input#selections_1_#{@so_at_1_02.id}").should be_checked
      end
      within("tr[data-displayed-pair='pair_#{@subj_art_1.id}_2_#{@so_at_1_03.id}']") do
        page.should have_content("AT.1.03")
        page.should have_content("==")
        page.should have_css("input#selections_2_#{@so_at_1_03.id}")
        find("input#selections_2_#{@so_at_1_03.id}").should be_checked
      end
      within("tr[data-displayed-pair='pair_#{@subj_art_1.id}_3_#{@so_at_1_04.id}']") do
        page.should have_content("AT.1.04")
        page.should have_content("==")
        page.should have_css("input#selections_3_#{@so_at_1_04.id}")
        find("input#selections_3_#{@so_at_1_04.id}").should be_checked
      end
      page.should_not have_css("tr[data-displayed-pair='pair_#{@subj_art_2.id}_2_']")

      find('#save_matches').click

      # sleep 20
      # save_and_open_page

      # Art 2 with two preselected identical pairs
      page.should have_content('Match Old LOs to New LOs')
      within('thead.table-title') do
        page.should have_content("Processing #{@subj_art_2.name} of All Subjects")
      end
      # confirm current subject los are displayed and others are not
      within('form table') do
        page.should_not have_content("AT.1.01")
        page.should_not have_content("MA.1.12")
      end
      within("tr[data-displayed-pair='pair_#{@subj_art_2.id}_4_#{@so_at_2_01.id}']") do
        page.should have_css("td.new_lo_desc", text: "AT.2.01 Changed")
        page.should have_content("~=")
        page.should have_css("input[name='selections[4]']")
        page.should have_css("input#selections_4_#{@so_at_2_01.id}")
        find("input#selections_4_#{@so_at_2_01.id}").should_not be_checked
        page.should have_css("td.old_lo_desc", text: "AT.2.01 Original")
      end
      within("tr[data-displayed-pair='pair_#{@subj_art_2.id}__#{@so_at_2_01.id}']") do
        page.should have_css("td.new_lo_desc", text: "")
        page.should have_content("-")
        page.should have_css("input[name='selections[-#{@so_at_2_01.id}]']")
        page.should have_css("input#selections__#{@so_at_2_01.id}")
        find("input#selections__#{@so_at_2_01.id}").should_not be_checked
        page.should have_css("td.old_lo_desc", text: "AT.2.01 Original")
      end
      within("tr[data-displayed-pair='pair_#{@subj_art_2.id}_5_#{@so_at_2_02.id}']") do
        page.should have_css("td.new_lo_desc", text: "AT.2.02 Original")
        page.should have_content("==")
        page.should have_css("input[name='selections[5]']")
        page.should have_css("input#selections_5_#{@so_at_2_02.id}")
        find("input#selections_5_#{@so_at_2_02.id}").should be_checked
        page.should have_css("td.old_lo_desc", text: "AT.2.02 Original")
      end
      within("tr[data-displayed-pair='pair_#{@subj_art_2.id}_6_#{@so_at_2_03.id}']") do
        page.should have_css("td.new_lo_desc", text: "AT.2.03 Original")
        page.should have_content("==")
        page.should have_css("input[name='selections[6]']")
        page.should have_css("input#selections_6_#{@so_at_2_03.id}")
        find("input#selections_6_#{@so_at_2_03.id}").should be_checked
        page.should have_css("td.old_lo_desc", text: "AT.2.03 Original")
      end
      within("tr[data-displayed-pair='pair_#{@subj_art_2.id}__#{@so_at_2_04.id}']") do
        page.should have_css("td.new_lo_desc", text: "")
        page.should have_content("-")
        page.should have_css("input[name='selections[-#{@so_at_2_04.id}]']")
        page.should have_css("input#selections__#{@so_at_2_04.id}")
        find("input#selections__#{@so_at_2_04.id}").should_not be_checked
        page.should have_css("td.old_lo_desc", text: "AT.2.04 Original")
      end
      within("tr[data-displayed-pair='pair_#{@subj_art_2.id}_7_#{@so_at_2_04.id}']") do
        page.should have_css("td.new_lo_code", text: "AT 2.04")
        page.should have_css("td.new_lo_desc", text: "AT.2.04 Original")
        page.should have_content("~=")
        page.should have_css("input[name='selections[7]']")
        page.should have_css("input#selections_7_#{@so_at_2_04.id}")
        find("input#selections_7_#{@so_at_2_04.id}").should_not be_checked
        page.should have_css("td.old_lo_desc", text: "AT.2.04 Original")
      end
      within("tr[data-displayed-pair='pair_#{@subj_art_2.id}_7_#{@so_at_2_03.id}']") do
        page.should have_css("td.new_lo_code", text: "AT 2.04")
        page.should have_css("td.new_lo_desc", text: "AT.2.04 Original")
        page.should have_content("~=")
        page.should have_css("input[name='selections[7]']")
        page.should have_css("input#selections_7_#{@so_at_2_03.id}")
        find("input#selections_7_#{@so_at_2_03.id}").should_not be_checked
        page.should have_css("td.old_lo_desc", text: "AT.2.03 Original")
      end
      within("tr[data-displayed-pair='pair_#{@subj_art_2.id}_7_#{@so_at_2_02.id}']") do
        page.should have_css("td.new_lo_code", text: "AT 2.04")
        page.should have_css("td.new_lo_desc", text: "AT.2.04 Original")
        page.should have_content("~=")
        page.should have_css("input[name='selections[7]']")
        page.should have_css("input#selections_7_#{@so_at_2_02.id}")
        find("input#selections_7_#{@so_at_2_02.id}").should_not be_checked
        page.should have_css("td.old_lo_desc", text: "AT.2.02 Original")
      end
      within("tr[data-displayed-pair='pair_#{@subj_art_2.id}_7_#{@so_at_2_01.id}']") do
        page.should have_css("td.new_lo_code", text: "AT 2.04")
        page.should have_css("td.new_lo_desc", text: "AT.2.04 Original")
        page.should have_content("~=")
        page.should have_css("input[name='selections[7]']")
        page.should have_css("input#selections_7_#{@so_at_2_01.id}")
        find("input#selections_7_#{@so_at_2_01.id}").should_not be_checked
        page.should have_css("td.old_lo_desc", text: "AT.2.01 Original")
      end

      find('input#selections_4_5').click
      # find('input#selections__8').click
      find('input#selections_7_8').click

      # sleep 10
      # save_and_open_page

      find('#save_matches').click
      # sleep 10
      # save_and_open_page

      # Capstone 3s1 with all preselected identical pairs
      page.should have_content('Match Old LOs to New LOs')
      within('thead.table-title') do
        page.should have_content("Processing #{@subj_capstone_3s1.name} of All Subjects")
      end
      # confirm current subject los are displayed and others are not
      within('form table') do
        page.should_not have_content("AT.1.01")
        page.should_not have_content("MA.1.12")
      end
      within("tr[data-displayed-pair='pair_#{@subj_capstone_3s1.id}_8_#{@cp_3_01.id}']") do
        page.should have_css("td.new_lo_desc", text: "CP.3.01 Original")
        page.should have_content("==")
        page.should have_css("input[name='selections[8]']")
        page.should have_css("input#selections_8_#{@cp_3_01.id}")
        find("input#selections_8_#{@cp_3_01.id}").should be_checked
        page.should have_css("td.old_lo_desc", text: "CP.3.01 Original")
      end
      within("tr[data-displayed-pair='pair_#{@subj_capstone_3s1.id}_9_#{@cp_3_02.id}']") do
        page.should have_css("td.new_lo_desc", text: "CP.3.02 Original")
        page.should have_content("==")
        page.should have_css("input[name='selections[9]']")
        page.should have_css("input#selections_9_#{@cp_3_02.id}")
        find("input#selections_9_#{@cp_3_02.id}").should be_checked
        page.should have_css("td.old_lo_desc", text: "CP.3.02 Original")
      end
      within("tr[data-displayed-pair='pair_#{@subj_capstone_3s1.id}_10_#{@cp_3_03.id}']") do
        page.should have_css("td.new_lo_desc", text: "CP.3.03 Original")
        page.should have_content("==")
        page.should have_css("input[name='selections[10]']")
        page.should have_css("input#selections_10_#{@cp_3_03.id}")
        find("input#selections_10_#{@cp_3_03.id}").should be_checked
        page.should have_css("td.old_lo_desc", text: "CP.3.03 Original")
      end
      within("tr[data-displayed-pair='pair_#{@subj_capstone_3s1.id}_11_#{@cp_3_04.id}']") do
        page.should have_css("td.new_lo_desc", text: "CP.3.04 Original")
        page.should have_content("==")
        page.should have_css("input[name='selections[11]']")
        page.should have_css("input#selections_11_#{@cp_3_04.id}")
        find("input#selections_11_#{@cp_3_04.id}").should be_checked
        page.should have_css("td.old_lo_desc", text: "CP.3.04 Original")
      end

      find('#save_matches').click
      # sleep 30
      save_and_open_page

      # Math 1 with all preselected identical pairs
      page.should have_content('Match Old LOs to New LOs')
      within('thead.table-title') do
        page.should have_content("Processing #{@subj_math_1.name} of All Subjects")
      end
      # confirm current subject los are displayed and others are not
      within('form table') do
        page.should_not have_content("AT.1.01")
      end
      page.should have_css("tr[data-displayed-pair='pair_#{@subj_math_1.id}_12_13']")
      within("tr[data-displayed-pair='pair_#{@subj_math_1.id}_12_#{@ma_1_01.id}']") do
        page.should have_css("td.new_lo_desc", text: "Will be changed significantly.")
        page.should have_content("~=")
        page.should have_css("input[name='selections[12]']")
        page.should have_css("input#selections_12_#{@ma_1_01.id}")
        find("input#selections_12_#{@ma_1_01.id}").should_not be_checked
        page.should have_css("td.old_lo_desc", text: "Will be changed significantly. Create, interpret and analyze trigonometric ratios that model real-world situations.")
      end
      page.should have_css("tr[data-displayed-pair='pair_#{@subj_math_1.id}__13']")
      within("tr[data-displayed-pair='pair_#{@subj_math_1.id}__#{@ma_1_01.id}']") do
        page.should have_css("td.new_lo_desc", text: "")
        page.should have_content("-")
        page.should have_css("input[name='selections[-#{@ma_1_01.id}]']")
        page.should have_css("input#selections__#{@ma_1_01.id}")
        find("input#selections__#{@ma_1_01.id}").should_not be_checked
        page.should have_css("td.old_lo_desc", text: "Will be changed significantly. Create, interpret and analyze trigonometric ratios that model real-world situations.")
      end
      page.should have_css("tr[data-displayed-pair='pair_#{@subj_math_1.id}__14']")
      within("tr[data-displayed-pair='pair_#{@subj_math_1.id}__#{@ma_1_02.id}']") do
        page.should have_css("td.new_lo_desc", text: "")
        page.should have_content("-")
        page.should have_css("input[name='selections[-#{@ma_1_02.id}]']")
        page.should have_css("input#selections__#{@ma_1_02.id}")
        find("input#selections__#{@ma_1_02.id}").should_not be_checked
        page.should have_css("td.old_lo_desc", text: "Will be deleted. Apply the relationships between 2-D and 3-D objects in modeling situations.")
      end
      page.should have_css("tr[data-displayed-pair='pair_#{@subj_math_1.id}__15']")
      within("tr[data-displayed-pair='pair_#{@subj_math_1.id}__#{@ma_1_03.id}']") do
        page.should have_css("td.new_lo_desc", text: "")
        page.should have_content("-")
        page.should have_css("input[name='selections[-#{@ma_1_03.id}]']")
        page.should have_css("input#selections__#{@ma_1_03.id}")
        find("input#selections__#{@ma_1_03.id}").should_not be_checked
        page.should have_css("td.old_lo_desc", text: "Will have the MA.1.03 code without the period. Understand similarity and use the concept for scaling to solve problems.")
      end
      page.should have_css("tr[data-displayed-pair='pair_#{@subj_math_1.id}_18_20']")
      within("tr[data-displayed-pair='pair_#{@subj_math_1.id}_18_#{@ma_1_08.id}']") do
        page.should have_css("td.new_lo_desc", text: "Will be switched with 04. Create, interpret and analyze exponential and logarithmic functions that model real-world situations.")
        page.should have_content("~=")
        page.should have_css("input[name='selections[18]']")
        page.should have_css("input#selections_18_#{@ma_1_08.id}")
        find("input#selections_18_#{@ma_1_08.id}").should_not be_checked
        page.should have_css("td.old_lo_desc", text: "Will be switched with 04. Create, interpret and analyze exponential and logarithmic functions that model real-world situations.")
      end
      page.should have_css("tr[data-displayed-pair='pair_#{@subj_math_1.id}_18_16']")
      within("tr[data-displayed-pair='pair_#{@subj_math_1.id}_18_#{@ma_1_04.id}']") do
        page.should have_css("td.new_lo_desc", text: "Will be switched with 04. Create, interpret and analyze exponential and logarithmic functions that model real-world situations.")
        page.should have_content("~=")
        page.should have_css("input[name='selections[18]']")
        page.should have_css("input#selections_18_#{@ma_1_04.id}")
        find("input#selections_18_#{@ma_1_04.id}").should_not be_checked
        page.should have_css("td.old_lo_desc", text: "will be switched with 08. Apply volume formulas (pyramid, cones, spheres, prisms).")
      end
      page.should have_css("tr[data-displayed-pair='pair_#{@subj_math_1.id}__16']")
      within("tr[data-displayed-pair='pair_#{@subj_math_1.id}__#{@ma_1_04.id}']") do
        page.should have_css("td.new_lo_desc", text: "")
        page.should have_content("-")
        page.should have_css("input[name='selections[-#{@ma_1_04.id}]']")
        page.should have_css("input#selections__#{@ma_1_04.id}")
        find("input#selections__#{@ma_1_04.id}").should_not be_checked
        page.should have_css("td.old_lo_desc", text: "will be switched with 08. Apply volume formulas (pyramid, cones, spheres, prisms).")
      end
      page.should have_css("tr[data-displayed-pair='pair_#{@subj_math_1.id}_15_17']")
      within("tr[data-displayed-pair='pair_#{@subj_math_1.id}_15_#{@ma_1_05.id}']") do
        page.should have_css("td.new_lo_desc", text: "Will be switched to semester 1&2. Create, interpret and analyze functions, particularly linear and step functions that model real-world situations.")
        page.should have_content("==")
        page.should have_css("input[name='selections[15]']")
        page.should have_css("input#selections_15_#{@ma_1_05.id}")
        find("input#selections_15_#{@ma_1_05.id}").should be_checked
        page.should have_css("td.old_lo_desc", text: "Will be switched to semester 1&2. Create, interpret and analyze functions, particularly linear and step functions that model real-world situations.")
      end
      page.should have_css("tr[data-displayed-pair='pair_#{@subj_math_1.id}_16_18']")
      within("tr[data-displayed-pair='pair_#{@subj_math_1.id}_16_#{@ma_1_06.id}']") do
        page.should have_css("td.new_lo_desc", text: "Will be unchanged. Analyze, display and describe quantitative data with a focus on standard deviation.")
        page.should have_content("==")
        page.should have_css("input[name='selections[16]']")
        page.should have_css("input#selections_16_#{@ma_1_06.id}")
        find("input#selections_16_#{@ma_1_06.id}").should be_checked
        page.should have_css("td.old_lo_desc", text: "Will be unchanged. Analyze, display and describe quantitative data with a focus on standard deviation.")
      end
      page.should have_css("tr[data-displayed-pair='pair_#{@subj_math_1.id}_17_19']")
      within("tr[data-displayed-pair='pair_#{@subj_math_1.id}_17_#{@ma_1_07.id}']") do
        page.should have_css("td.new_lo_desc", text: "Will be switched to semester 2. Create, interpret and analyze quadratic functions that model real-world situations.")
        page.should have_content("==")
        page.should have_css("input[name='selections[17]']")
        page.should have_css("input#selections_17_#{@ma_1_07.id}")
        find("input#selections_17_#{@ma_1_07.id}").should be_checked
        page.should have_css("td.old_lo_desc", text: "Will be switched to semester 2. Create, interpret and analyze quadratic functions that model real-world situations.")
      end
      page.should have_css("tr[data-displayed-pair='pair_#{@subj_math_1.id}_14_16']")
      within("tr[data-displayed-pair='pair_#{@subj_math_1.id}_14_#{@ma_1_04.id}']") do
        page.should have_css("td.new_lo_desc", text: "will be switched with 08. Apply volume formulas (pyramid, cones, spheres, prisms).")
        page.should have_content("~=")
        page.should have_css("input[name='selections[14]']")
        page.should have_css("input#selections_14_#{@ma_1_04.id}")
        find("input#selections_14_#{@ma_1_04.id}").should_not be_checked
        page.should have_css("td.old_lo_desc", text: "will be switched with 08. Apply volume formulas (pyramid, cones, spheres, prisms).")
      end
      page.should have_css("tr[data-displayed-pair='pair_#{@subj_math_1.id}_14_20']")
      within("tr[data-displayed-pair='pair_#{@subj_math_1.id}_14_#{@ma_1_08.id}']") do
        page.should have_css("td.new_lo_desc", text: "will be switched with 08. Apply volume formulas (pyramid, cones, spheres, prisms).")
        page.should have_content("~=")
        page.should have_css("input[name='selections[14]']")
        page.should have_css("input#selections_14_#{@ma_1_08.id}")
        find("input#selections_14_#{@ma_1_08.id}").should_not be_checked
        page.should have_css("td.old_lo_desc", text: "Will be switched with 04. Create, interpret and analyze exponential and logarithmic functions that model real-world situations.")
      end
      page.should have_css("tr[data-displayed-pair='pair_#{@subj_math_1.id}__20']")
      within("tr[data-displayed-pair='pair_#{@subj_math_1.id}__#{@ma_1_08.id}']") do
        page.should have_css("td.new_lo_desc", text: "")
        page.should have_content("-")
        page.should have_css("input[name='selections[-#{@ma_1_08.id}]']")
        page.should have_css("input#selections__#{@ma_1_08.id}")
        find("input#selections__#{@ma_1_08.id}").should_not be_checked
        page.should have_css("td.old_lo_desc", text: "Will be switched with 04. Create, interpret and analyze exponential and logarithmic functions that model real-world situations.")
      end
      page.should have_css("tr[data-displayed-pair='pair_#{@subj_math_1.id}_19_21']")
      within("tr[data-displayed-pair='pair_#{@subj_math_1.id}_19_#{@ma_1_09.id}']") do
        page.should have_css("td.new_lo_desc", text: "Will have a description that is very similar to 10.")
        page.should have_content("==")
        page.should have_css("input[name='selections[19]']")
        page.should have_css("input#selections_19_#{@ma_1_09.id}")
        find("input#selections_19_#{@ma_1_09.id}").should be_checked
        page.should have_css("td.old_lo_desc", text: "Will have a description that is very similar to 10.")
      end
      page.should have_css("tr[data-displayed-pair='pair_#{@subj_math_1.id}_20_22']")
      within("tr[data-displayed-pair='pair_#{@subj_math_1.id}_20_#{@ma_1_10.id}']") do
        page.should have_css("td.new_lo_desc", text: "Will have a description that is very similar to 09.")
        page.should have_content("==")
        page.should have_css("input[name='selections[20]']")
        page.should have_css("input#selections_20_#{@ma_1_10.id}")
        find("input#selections_20_#{@ma_1_10.id}").should be_checked
        page.should have_css("td.old_lo_desc", text: "Will have a description that is very similar to 09.")
      end
      page.should have_css("tr[data-displayed-pair='pair_#{@subj_math_1.id}_21_23']")
      within("tr[data-displayed-pair='pair_#{@subj_math_1.id}_21_#{@ma_1_11.id}']") do
        page.should have_css("td.new_lo_desc", text: "Will have period removed from description. Create, interpret and analyze systems of linear functions that model real-world situations")
        page.should have_content("~=")
        page.should have_css("input[name='selections[21]']")
        page.should have_css("input#selections_21_#{@ma_1_11.id}")
        find("input#selections_21_#{@ma_1_11.id}").should_not be_checked
        page.should have_css("td.old_lo_desc", text: "Will have period removed from description. Create, interpret and analyze systems of linear functions that model real-world situations.")
      end
      page.should have_css("tr[data-displayed-pair='pair_#{@subj_math_1.id}__23']")
      within("tr[data-displayed-pair='pair_#{@subj_math_1.id}__#{@ma_1_11.id}']") do
        page.should have_css("td.new_lo_desc", text: "")
        page.should have_content("-")
        page.should have_css("input[name='selections[-#{@ma_1_11.id}]']")
        page.should have_css("input#selections__#{@ma_1_11.id}")
        find("input#selections__#{@ma_1_11.id}").should_not be_checked
        page.should have_css("td.old_lo_desc", text: "Will have period removed from description. Create, interpret and analyze systems of linear functions that model real-world situations.")
      end
      page.should have_css("tr[data-displayed-pair='pair_#{@subj_math_1.id}_22_24']")
      within("tr[data-displayed-pair='pair_#{@subj_math_1.id}_22_#{@ma_1_12.id}']") do
        page.should have_css("td.new_lo_desc", text: "Will be reactivated. Apply determinants and their properties in real-world situations.")
        page.should have_content("==^")
        page.should have_css("input[name='selections[22]']")
        page.should have_css("input#selections_22_#{@ma_1_12.id}")
        find("input#selections_22_#{@ma_1_12.id}").should be_checked
        page.should have_css("td.old_lo_desc", text: "Will be reactivated. Apply determinants and their properties in real-world situations.")
      end
      page.should have_css("tr[data-displayed-pair='pair_#{@subj_math_1.id}_13_15']")
      within("tr[data-displayed-pair='pair_#{@subj_math_1.id}_13_#{@ma_1_03.id}']") do
        page.should have_css("td.new_lo_desc", text: "Will have the MA.1.03 code without the period. Understand similarity and use the concept for scaling to solve problems.")
        page.should have_content("~=")
        page.should have_css("input[name='selections[13]']")
        page.should have_css("input#selections_13_#{@ma_1_03.id}")
        find("input#selections_13_#{@ma_1_03.id}").should_not be_checked
        page.should have_css("td.old_lo_desc", text: "Will have the MA.1.03 code without the period. Understand similarity and use the concept for scaling to solve problems.")
      end

      find('#save_matches').click
      # sleep 30
      # save_and_open_page

    end # within #page-content
  end # def bulk_upload_all_matching


end


describe "Subject Outcomes Bulk Upload LOs Invalid School", js:true do
  before (:each) do

    create_and_load_model_school
    create_school1

  end

  describe "as system administrator" do
    before do
      @system_administrator = FactoryGirl.create :system_administrator
      sign_in(@system_administrator)
      set_users_school(@school1)
    end
    it { cannot_see_bulk_upload_los }
  end

  ##################################################
  # test methods

  def cannot_see_bulk_upload_los
    visit upload_lo_file_subject_outcomes_path()
    assert_equal("/subject_outcomes/upload_lo_file", current_path)
    # page.should have_content('Upload Learning Outcomes from Curriculum')
    page.should have_content('This school is not configured for Bulk Uploading Learning Outcomes')
  end

end
