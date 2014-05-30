require 'test_helper'

class ProcessorControllerTest < ActionController::TestCase
  test "should get bypid" do
    get :bypid
    assert_response :success
  end

  test "should get bycollection" do
    get :bycollection
    assert_response :success
  end

  test "should get byinstitution" do
    get :byinstitution
    assert_response :success
  end

  test "should get byfile" do
    get :byfile
    assert_response :success
  end

end
