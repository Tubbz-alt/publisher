class EditionPresenterFactory
  class << self
    def get_presenter(edition)
      presenter_class(edition.class.to_s).constantize.new(edition)
    end

    def presenter_class(edition_class)
      case edition_class
      when "HelpPageEdition"
        "Formats::HelpPagePresenter"
      when "AnswerEdition"
        "Formats::AnswerPresenter"
      else
        "Formats::GenericEditionPresenter"
      end
    end
  end
end