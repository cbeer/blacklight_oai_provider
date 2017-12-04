require 'rails/generators'

class TestAppGenerator < Rails::Generators::Base
  source_root File.expand_path("../../../../spec/test_app_templates", __FILE__)

  # if you need to generate any additional configuration
  # into the test app, this generator will be run immediately
  # after setting up the application

  def run_blacklight_generator
    say_status("warning", "GENERATING BL", :yellow)

    generate 'blacklight:install', '--devise'
  end

  # Add favicon.ico to asset path
  # ADD THIS LINE Rails.application.config.assets.precompile += %w( favicon.ico )
  # TO config/assets.rb
  def add_favicon_to_asset_path
    say_status("warning", "ADDING FAVICON TO ASSET PATH", :yellow)

    append_to_file 'config/initializers/assets.rb' do
      'Rails.application.config.assets.precompile += %w( favicon.ico )'
    end
  end

  # Override solr.yml to match settings needed for solr_wrapper.
  def update_solr_config
    [:solr, :blacklight].each do |key|
      say_status("warning", "COPYING #{key}.YML".upcase, :yellow)

      remove_file "config/#{key}.yml"
      copy_file "config/solr.yml", "config/#{key}.yml"
    end
  end

  def install_engine
    say_status("warning", "GENERATING BL OAI PLUGIN", :yellow)

    generate 'blacklight_oai_provider:install'
  end

  def add_test_blacklight_oai_config
    say_status("warning", "ADDING BL OIA-PMH CONFIG")

    insert_into_file "app/controllers/catalog_controller.rb", after: "    config.default_solr_params = { \n" do
      "      :fl => '*',\n"
    end

    insert_into_file "app/controllers/catalog_controller.rb", after: "  configure_blacklight do |config|\n" do
      <<-CONFIG
    config.default_document_solr_params = {
      :qt => 'search',
      :fl => '*',
      :rows => 1,
      :q => '{!raw f=id v=$id}'
    }
      CONFIG
    end

    insert_into_file "app/controllers/catalog_controller.rb", after: "configure_blacklight do |config|\n" do
      <<-CONFIG
    config.oai = {
      :provider => {
        :repository_name => 'Test Repository',
        :repository_url => 'http://localhost',
        :record_prefix => 'oai:test',
        :admin_email => 'root@localhost',
        :deletion_support => 'persistent',
        :sample_id => '109660'
      },
      :document => {
        :model => SolrDocument,
        :set_fields => [
          { label: 'language', solr_field: 'language_facet' }
        ],
        :limit => 25
      }
    }
      CONFIG
    end

    insert_into_file "app/models/solr_document.rb", after: "include BlacklightOaiProvider::SolrDocument\n" do
      <<-CONFIG
  field_semantics.merge!(
    title: "title_display",
    creator: "author_display",
    date: "pub_date",
    subject: "subject_topic_facet",
    format: "format",
    language: "language_facet"
  )
      CONFIG
    end
  end
end
