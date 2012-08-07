require 'test_helper'

class RecordsControllerTest < ActionController::TestCase
    include Devise::TestHelpers

    def setup
        sign_in users(:admin)
    end

    test 'index' do
        n_domains = Domain.find(domains(:dom1)).records.where('type != ?', 'SOA').count
        assert n_domains == 8 # with soa

        xhr :get, :index, {:domain_id => domains(:dom1).id, :per_page => 99999}
        assert_response :success
        assert_not_nil  assigns(:records)
        assert          assigns(:records).size == 8
        assert_select   'table#record-table tbody tr.show-record', 8

        xhr :get, :index, {:domain_id => domains(:dom1).id, :per_page => 5}
        assert_response :success
        assert_not_nil  assigns(:records)
        assert          assigns(:records).size == 5
        assert_select   'table#record-table tbody tr.show-record', 5

        xhr :get, :index, {:domain_id => domains(:dom1).id, :per_page => 5, :page => 2}
        assert_response :success
        assert_not_nil  assigns(:records)
        assert          assigns(:records).size == 3
        assert_select   'table#record-table tbody tr.show-record', 3

        xhr :get, :index, {:domain_id => domains(:dom1).id, :per_page => 5, :page => 3}
        assert_response :success
        assert_not_nil  assigns(:records)
        assert_empty    assigns(:records)
        assert_select   'table#record-table tbody tr.show-record', 0
    end

    # test 'show' do
    #     xhr :get, :show, {:id => records(:dom1).id, :per_page => 99999}
    # end

    test 'create A' do
        n_records = Record.count

        params = {
            :name    => '',
            :type    => 'A',
            :content => '10.0.1.100'
        }

        xhr :post, :create, { :record => params , :domain_id => domains(:dom1) }
        assert_response :unprocessable_entity # no name
        assert          assigns(:record).errors.keys.include?(:name)

        xhr :post, :create, { :record => params.merge!(:name => 'new-a-name'), :domain_id => domains(:dom1) }
        assert_response :success
        assert_not_nil  assigns(:record)
        assert_empty    assigns(:record).errors

        assert_not_nil record = Record.where(:domain_id => domains(:dom1).id, :name => params[:name]).first
        assert         record.is_a?(A)
        assert         record.domain  == domains(:dom1)
        assert         record.name    == params[:name]
        assert         record.type    == params[:type]
        assert         record.content == params[:content]
        assert_nil     record.ttl
        assert         record.prio.blank?
        assert         Record.count == (n_records + 1)
    end

    test 'create MX' do
        params = {
            :name    => 'new-mx',
            :type    => 'MX',
            :content => records(:dom1_a1).name,
            :ttl     => 86402
        }

        xhr :post, :create, { :record => params , :domain_id => domains(:dom1) }
        assert_response :unprocessable_entity # no prio
        assert          assigns(:record).errors.keys.include?(:prio)

        xhr :post, :create, { :record => params.merge!({:prio => 10}), :domain_id => domains(:dom1) }
        assert_response :success
        assert_not_nil  assigns(:record)
        assert_empty    assigns(:record).errors

        assert_not_nil record = Record.where(:domain_id => domains(:dom1).id, :name => params[:name]).first
        assert         record.is_a?(MX)
        assert         record.domain  == domains(:dom1)
        assert         record.name    == params[:name]
        assert         record.type    == params[:type]
        assert         record.content == params[:content]
        assert         record.ttl     == params[:ttl].to_s
        assert         record.prio    == params[:prio]
    end

    test 'update A' do
        params = {
            :name    => '',
            :type    => 'A',
            :content => '10.0.1.101',
            :ttl     => 86411
        }

        xhr :put, :update, { :record => params , :id => records(:dom1_a1) }
        assert_response :unprocessable_entity # no name
        assert          assigns(:record).errors.keys.include?(:name)

        xhr :put, :update, { :record => params.merge!(:name => 'new-a-name') , :id => records(:dom1_a1) }
        assert_response :success
        assert_not_nil  assigns(:record)
        assert_empty    assigns(:record).errors

        assert_not_nil record = Record.find(records(:dom1_a1))
        assert         record.is_a?(A)
        assert         record.domain  == domains(:dom1)
        assert         record.name    == params[:name]
        assert         record.type    == params[:type]
        assert         record.content == params[:content]
        assert         record.ttl     == params[:ttl].to_s
        assert         record.prio.blank?
    end

    test 'destroy' do
        n_records = Record.count

        xhr :delete, :destroy, { :id => records(:dom1_a1) }
        assert_response :success
        assert_not_nil  assigns(:record)
        assert          assigns(:record).id == records(:dom1_a1).id
        assert_raises   ActiveRecord::RecordNotFound do; Record.find(records(:dom1_a1)); end;
        assert          Record.count == (n_records - 1)
    end
end
