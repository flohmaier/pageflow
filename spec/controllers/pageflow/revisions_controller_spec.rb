require 'spec_helper'

module Pageflow
  describe RevisionsController do
    routes { Engine.routes }
    render_views

    def main_app
      Rails.application.class.routes.url_helpers
    end

    describe '#show' do
      it 'responds with success for members' do
        user = create(:user)
        entry = create(:entry, :with_member => user)
        revision = create(:revision, :entry => entry)

        sign_in(user)
        get(:show, :id => revision)

        expect(response.status).to eq(200)
      end

      it 'renders widgets which are enabled in preview' do
        Pageflow.config.widget_types.register(TestWidgetType.new(:name => 'test_widget',
                                                                 :enabled_in_preview => true,
                                                                 :rendered_head_fragment => '<meta name="some_test" content="value">',
                                                                 :rendered => '<div class="test_widget"></div>'))
        user = create(:user)
        entry = create(:entry, :with_member => user)
        revision = create(:revision, :entry => entry)
        create(:widget, :subject => revision, :type_name => 'test_widget')

        sign_in(user)
        get(:show, :id => revision)

        expect(response.body).to have_selector('div.test_widget')
        expect(response.body).to have_selector('head meta[name=some_test]', :visible => false)
      end

      it 'does not render widgets which are disabled in preview' do
        Pageflow.config.widget_types.register(TestWidgetType.new(:name => 'test_widget',
                                                                 :enabled_in_preview => false,
                                                                 :rendered_head_fragment => '<meta name="some_test" content="value">',
                                                                 :rendered => '<div class="test_widget"></div>'))
        user = create(:user)
        entry = create(:entry, :with_member => user)
        revision = create(:revision, :entry => entry)
        create(:widget, :subject => revision, :type_name => 'test_widget')

        sign_in(user)
        get(:show, :id => revision)

        expect(response.body).not_to have_selector('div.test_widget')
      end

      it 'requires the signed in user to be member of the parent entry' do
        user = create(:user)
        revision = create(:revision)

        sign_in(user)
        get(:show, :id => revision)

        expect(response.status).to redirect_to(main_app.admin_root_path)
      end

      it 'requires authentication' do
        revision = create(:revision)

        get(:show, :id => revision)

        expect(response).to redirect_to(main_app.new_user_session_path)
      end
    end

    describe '#depublish_current' do
      it 'depublished current revision' do
        user = create(:user)
        entry = create(:entry, :with_member => user)

        sign_in(user)
        delete(:depublish_current, :entry_id => entry)

        expect(response.status).to redirect_to(main_app.admin_entry_path(entry))
      end

      it 'depublished current revision' do
        user = create(:user)
        entry = create(:entry, :published, :with_member => user)

        sign_in(user)
        delete(:depublish_current, :entry_id => entry)

        expect(entry).not_to be_published
      end

      it 'requires the signed in user to be member of the parent entry' do
        user = create(:user)
        entry = create(:entry)

        sign_in(user)
        delete(:depublish_current, :entry_id => entry)

        expect(response.status).to redirect_to(main_app.admin_root_path)
      end

      it 'requires authentication' do
        entry = create(:entry)

        delete(:depublish_current, :entry_id => entry)

        expect(response).to redirect_to(main_app.new_user_session_path)
      end
    end
  end
end
