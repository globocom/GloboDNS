require 'test_helper'

class DomainsControllerTest < ActionController::TestCase
    include Devise::TestHelpers

    def setup
        sign_in users(:admin)
    end

    test 'index' do
        get :index
        assert_response :success
        assert_not_nil assigns(:domains)
    end

    test 'show' do
        get :show, { :id => domains(:dom1).id }
        assert_response :success
        assert_not_nil assigns(:domain)
        assigns(:domain).id   == 1
        assigns(:domain).name == domains(:dom1).name
        assigns(:domain).ttl  == domains(:dom1).ttl
    end

    test 'create' do
        params = {
            :name           => 'created.example.com',
            :ttl            => 86411,
            :authority_type => Domain::MASTER,
            :primary_ns     => 'nscreated.example.com.',
            :contact        => 'root.created.example.com.',
            :refresh        => 10801,
            :retry          => 3601,
            :expire         => 604801,
            :minimum        => 7201
        }

        xhr :post, :create, { :domain => params }

        assert_response :success
        assert_not_nil  assigns(:domain)
        assert_empty    assigns(:domain).errors

        assert domain = Domain.where('name' => params[:name]).first
        assert domain.ttl                   == params[:ttl].to_s
        assert domain.soa_record.primary_ns == params[:primary_ns]
        assert domain.soa_record.contact    == params[:contact]
        assert domain.soa_record.refresh    == params[:refresh].to_s
        assert domain.soa_record.retry      == params[:retry].to_s
        assert domain.soa_record.expire     == params[:expire].to_s
        assert domain.soa_record.minimum    == params[:minimum].to_s
        assert domain.soa_record.content    =~ /#{params[:primary_ns]} #{params[:contact]} 0 #{params[:refresh]} #{params[:retry]} #{params[:expire]} #{params[:minimum]}/
    end

    test 'update' do
        params = {
            :name       => 'updatedname.example.com',
            :ttl        => 86402,
            :primary_ns => 'updatedns.example.com.',
            :contact    => 'updatedcontact.created.example.com.',
            :refresh    => 10802,
            :retry      => 3602,
            :expire     => 604802,
            :minimum    => 7202
        }

        xhr :put, :update, { :id => domains(:dom1).id, :domain => params }

        assert_response :success
        assert_not_nil  assigns(:domain)
        assert_empty    assigns(:domain).errors

        assert domain = Domain.find(domains(:dom1).id)
        assert domain.name                  == params[:name]
        assert domain.ttl                   == params[:ttl].to_s
        assert domain.soa_record.primary_ns == params[:primary_ns]
        assert domain.soa_record.contact    == params[:contact]
        assert domain.soa_record.refresh    == params[:refresh].to_s
        assert domain.soa_record.retry      == params[:retry].to_s
        assert domain.soa_record.expire     == params[:expire].to_s
        assert domain.soa_record.minimum    == params[:minimum].to_s
        assert domain.soa_record.content    =~ /#{params[:primary_ns]} #{params[:contact]} 0 #{params[:refresh]} #{params[:retry]} #{params[:expire]} #{params[:minimum]}/
    end

    test 'destroy' do
        n_domains = Domain.count

        delete :destroy, { :id => domains(:dom1).id }
        assert_response :redirect
        assert_not_nil assigns(:domain)
        assert assigns(:domain).id == domains(:dom1).id
        assert_raises ActiveRecord::RecordNotFound do Domain.find(domains(:dom1).id); end
        assert Domain.count == (n_domains - 1)
    end
end
