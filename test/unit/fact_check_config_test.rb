require "test_helper"

class FactCheckConfigTest < ActiveSupport::TestCase
  subject_prefix = "test"
  reply_to_address = "factcheck+1234@example.com"
  valid_subjects = ["‘[Some title]’ GOV.UK preview of new edition [5e6bb57b40f0b62656e3e184]",
                    "‘[Some title]’ GOV.UK preview of new edition [5e6bb57b40f0b62656e3e184] - ticket #5678",
                    "‘[123456]’ GOV.UK preview of new edition [5e6bb57b40f0b62656e3e184]",
                    "‘[123456]’ GOV.UK preview of new edition [5e6bb57b40f0b62656e3e184] - ticket #5678",
                    "I've edited the subject but left the ID at the end [5e6bb57b40f0b62656e3e184]",
                    "I've edited the subject and appended something [5e6bb57b40f0b62656e3e184] - ticket #2468"]
  valid_prefixed_subjects = valid_subjects.map { |subject| subject.gsub(/\[5e6bb57b40f0b62656e3e184\]/, "[test-5e6bb57b40f0b62656e3e184]") }

  should "fail on a nil reply-to address" do
    assert_raises ArgumentError do
      FactCheckConfig.new(nil)
    end
  end

  should "fail on an empty reply-to address" do
    assert_raises ArgumentError do
      FactCheckConfig.new("")
    end
  end

  should "return a static reply-to address regardless of id" do
    config = FactCheckConfig.new(reply_to_address)
    assert_equal reply_to_address, config.address
  end

  should "recognise a valid fact check subject" do
    config = FactCheckConfig.new(reply_to_address)
    valid_subjects.each do |valid_subject|
      assert config.item_id_from_string(valid_subject).present?
    end
  end

  should "recognise a valid fact check subject with a prefix" do
    config = FactCheckConfig.new(reply_to_address, subject_prefix)
    valid_prefixed_subjects.each do |valid_prefixed_subject|
      assert config.item_id_from_string(valid_prefixed_subject).present?
    end
    valid_subjects.each do |valid_subject|
      assert_nil config.item_id_from_string(valid_subject)
    end
  end

  should "not recognise an invalid fact check subject" do
    config = FactCheckConfig.new(reply_to_address)
    assert_nil config.item_id_from_string("Not a valid subject")
  end

  should "treat a subject prefixed with Re: as valid" do
    config = FactCheckConfig.new(reply_to_address)
    valid_subjects.each do |valid_subject|
      assert config.item_id_from_string("Re: " + valid_subject).present?
    end
  end

  should "not recognise a fact check subject with an empty ID" do
    config = FactCheckConfig.new(reply_to_address)
    assert_nil config.item_id_from_string("Not a valid subject []")
  end

  should "extract an item ID from a valid subject" do
    config = FactCheckConfig.new(reply_to_address)
    valid_subjects.each do |valid_subject|
      assert_equal "5e6bb57b40f0b62656e3e184", config.item_id_from_string(valid_subject)
    end
  end

  should "return nil if the input contains no valid ID" do
    config = FactCheckConfig.new(reply_to_address)

    assert_nil config.item_id_from_string("Not a valid subject (1234)")
    assert_nil config.item_id_from_string("Not a valid subject [notHexadecimal]")
  end

  should "raise an exception if there are multiple matches" do
    config = FactCheckConfig.new(reply_to_address)
    valid_subjects.each do |valid_subject|
      assert_raises ArgumentError do
        config.item_id_from_string(valid_subject + " [d682605bec3cf9b8906cf2bc]")
      end
    end
  end

  should "fall back to reading ID from body if none in subject" do
    config = FactCheckConfig.new(reply_to_address)
    assert_equal config.item_id_from_subject_or_body("subject without id",
                                                     "random text random text\n\nrandom text [5e6bb57b40f0b62656e3e184] more words\n\nwords words words words"),
                 "5e6bb57b40f0b62656e3e184"
  end

  should "ignore ID in body if subject has one" do
    config = FactCheckConfig.new(reply_to_address)
    assert_equal config.item_id_from_subject_or_body(valid_subjects.first,
                                                     "random text random text\n\nrandom text [d682605bec3cf9b8906cf2bc] more words\n\nwords words words words"),
                 "5e6bb57b40f0b62656e3e184"
  end

  should "fail if body has multiple IDs" do
    config = FactCheckConfig.new(reply_to_address)
    assert_raises ArgumentError do
      config.item_id_from_subject_or_body("subject without id",
                                          "random text random text\n\nrandom text [d682605bec3cf9b8906cf2bc] more words\n\nwords words [5e6bb57b40f0b62656e3e184] words words")
    end
  end
end
