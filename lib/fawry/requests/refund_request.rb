# frozen_string_literal: true

require 'digest'

module Fawry
  module Requests
    module RefundRequest
      def fire
        fawry_api_response = Connection.post(request[:path], request[:params], request[:body])
        response_body = JSON.parse(fawry_api_response.body)

        FawryResponse.new(response_body)
      end

      private

      def build_refund_request
        {
          path: 'refund',
          params: {},
          body: refund_request_transformed_params
        }
      end

      def request_params
        @request_params = params
      end

      def refund_request_transformed_params
        {
          merchantCode: request_params[:merchant_code],
          referenceNumber: request_params[:reference_number],
          refundAmount: request_params[:refund_amount],
          reason: request_params[:reason],
          signature: refund_request_signature
        }.compact
      end

      def validate_refund_params!
        contract = Contracts::RefundRequestContract.new.call(request_params)
        raise InvalidFawryRequest, contract.errors.to_h if contract.failure?
      end

      def refund_request_signature
        Digest::SHA256.hexdigest("#{request_params[:merchant_code]}#{request_params[:reference_number]}"\
                                 "#{format('%<refund_amount>.2f', refund_amount: request_params[:refund_amount])}"\
                                 "#{request_params[:reason]}#{request_params[:fawry_secure_key]}")
      end
    end
  end
end