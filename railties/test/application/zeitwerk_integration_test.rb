# frozen_string_literal: true

require "isolation/abstract_unit"
require "active_support/dependencies/zeitwerk_integration"

class ZeitwerkIntegrationTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::Isolation

  def setup
    build_app
  end

  def boot(env = "development")
    app(env)
  end

  def teardown
    teardown_app
  end

  def deps
    ActiveSupport::Dependencies
  end

  def decorated?
    deps.singleton_class < deps::ZeitwerkIntegration::Decorations
  end

  test "ActiveSupport::Dependencies is decorated by default" do
    boot

    assert decorated?
    assert_instance_of Zeitwerk::Loader, Rails.autoloader
    assert_instance_of Zeitwerk::Loader, Rails.once_autoloader
    assert_equal [Rails.autoloader, Rails.once_autoloader], Rails.autoloaders
  end

  test "ActiveSupport::Dependencies is not decorated in classic mode" do
    add_to_config 'config.autoloader = :classic'
    boot

    assert_not decorated?
    assert_nil Rails.autoloader
    assert_nil Rails.once_autoloader
    assert_empty Rails.autoloaders
  end

  test "constantize returns the value stored in the constant" do
    app_file "app/models/admin/user.rb", "class Admin::User; end"
    boot

    assert_same Admin::User, deps.constantize("Admin::User")
  end

  test "constantize raises if the constant is unknown" do
    boot

    assert_raises(NameError) { deps.constantize("Admin") }
  end

  test "safe_constantize returns the value stored in the constant" do
    app_file "app/models/admin/user.rb", "class Admin::User; end"
    boot

    assert_same Admin::User, deps.safe_constantize("Admin::User")
  end

  test "safe_constantize returns nil for unknown constants" do
    boot

    assert_nil deps.safe_constantize("Admin")
  end

  test "autoloaded_constants returns autoloaded constant paths" do
    app_file "app/models/admin/user.rb", "class Admin::User; end"
    app_file "app/models/post.rb", "class Post; end"
    boot

    assert Admin::User
    assert_equal ["Admin", "Admin::User"], deps.autoloaded_constants
  end

  test "autoloaded? says if a constant has been autoloaded" do
    app_file "app/models/user.rb", "class User; end"
    app_file "app/models/post.rb", "class Post; end"
    boot

    assert Post
    assert deps.autoloaded?("Post")
    assert deps.autoloaded?(Post)
    assert_not deps.autoloaded?("User")
  end

  test "eager loading" do
    $zeitwerk_integration_test_user = false
    $zeitwerk_integration_post_post = false

    app_file "app/models/user.rb", "class User; end; $zeitwerk_integration_test_user = true"
    app_file "app/models/post.rb", "class Post; end; $zeitwerk_integration_test_post = true"
    boot("production")

    assert $zeitwerk_integration_test_user
    assert $zeitwerk_integration_test_post
  end
end
