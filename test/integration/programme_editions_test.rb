require 'integration_test_helper'

class ProgrammeEditionsTest < JavascriptIntegrationTest
  def setup
    setup_users
  end

  test "should have editable part titles" do
    programme = FactoryGirl.create(:programme_edition, :title => "Benefit Example", :slug => "benefit-example")
    programme.save!

    visit "/admin/editions/#{programme.to_param}"

    assert_not_include page.body, "Part One"
    assert_not_include page.body, "part-one"

    click_on "Overview"
    within :css, "#overview" do
      fill_in "Title", :with => "Part One"
      fill_in "Body",  :with => "Body text"
      fill_in "Slug",  :with => "part-one"
    end

    within(:css, ".workflow_buttons") { click_on "Save" }

    assert_include page.body, "Programme edition was successfully updated."

    assert_include page.body, "Part One"
    assert_include page.body, "part-one"
  end
end
