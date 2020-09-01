require 'spec_helper'

describe 'Jbuilder#pages!' do
  context 'when there is no pagination for collection' do
    let(:collection) { OpenStruct.new(current_page: 0, total_pages: 0, size: 0) }
    let(:response_json) { File.read("spec/fixtures/no_pages_links.json").chomp }

    it { expect(build_json_for(collection)).to eq(response_json) }
  end

  context 'when there is pagination for collection' do
    let(:collection) { OpenStruct.new(current_page: 2, total_pages: 3, size: 1) }
    let(:response_json) { File.read("spec/fixtures/links.json").chomp }

    it { expect(build_json_for(collection)).to eq(response_json) }
  end

  context 'when there is additional params' do
    let(:collection) { OpenStruct.new(current_page: 2, total_pages: 3, size: 1) }
    let(:response_json) { File.read("spec/fixtures/links_with_additional_params.json").chomp }
    let(:additional) { { test: 'test' } }

    it { expect(build_json_for(collection, query_parameters: additional)).to eq(response_json) }
  end

  context 'when there are nil query_parameters it still works' do
    let(:collection) { OpenStruct.new(current_page: 2, total_pages: 3, size: 1) }
    let(:response_json) { File.read("spec/fixtures/links.json").chomp }
    let(:additional) { { test: 'test' } }

    it { expect(build_bad_json_for(collection)).to eq(response_json) }
  end

  context 'when there are string query_parameters it still works' do
    let(:collection) { OpenStruct.new(current_page: 2, total_pages: 3, size: 1) }
    let(:response_json) { File.read("spec/fixtures/links.json").chomp }
    let(:additional) { { test: 'test' } }

    it { expect(build_bad_json_for(collection)).to eq(response_json) }
  end

  context 'when parameter values are nil query_parameters compacts them' do
    let(:collection) { OpenStruct.new(current_page: 2, total_pages: 3, size: 1) }
    let(:response_json) { File.read("spec/fixtures/links.json").chomp }
    let(:additional) { { test: 'test' } }

    it { expect(build_more_bad_json_for(collection)).to eq(response_json) }
  end

  context 'when there is no pagination for collection it doesnt blow up' do
    let(:collection) { OpenStruct.new(current_page: 1, total_pages: 1, size: 1) }
    let(:response_json) { { links: { self: "https://api.example.com/v1/servers?page%5Bnumber%5D=1&page%5Bsize%5D=1" } }.to_json }

    it { expect(build_json_for(collection)).to eq(response_json) }
  end

  context 'when there are existing params for collection it doesnt repeat them' do
    let(:collection) { OpenStruct.new(current_page: 2, total_pages: 4, size: 1) }
    let(:response_json) {
      {
        links: {
          self: "https://api.example.com/v1/servers?bob=lob&page%5Bnumber%5D=2&page%5Bsize%5D=1",
          first: "https://api.example.com/v1/servers?bob=lob&page%5Bnumber%5D=1&page%5Bsize%5D=1",
          prev: "https://api.example.com/v1/servers?bob=lob&page%5Bnumber%5D=1&page%5Bsize%5D=1",
          next: "https://api.example.com/v1/servers?bob=lob&page%5Bnumber%5D=3&page%5Bsize%5D=1",
          last: "https://api.example.com/v1/servers?bob=lob&page%5Bnumber%5D=4&page%5Bsize%5D=1"
        }
      }.to_json
    }

    it { expect(build_json_for(collection, original_params: '?page%5Bnumber%5D=2&page%5Bsize%5D=1&bob=lob')).to eq(response_json) }
  end

  context 'when collection is nil' do
    it { expect(build_json_for(nil)).to eq("{}") }
  end

  context 'when there is a collection but it does not respond to all methods required' do
    let(:collection) { OpenStruct.new(current_page: 1, total_pages: 1) }

    it { expect(build_json_for(collection)).to eq("{}") }
  end

  context 'when total_pages raises an error it gets skipped' do
    let(:collection) { NonCountable.new }
    let(:response_json) {
      {
        links: {
          self: "https://api.example.com/v1/servers?bob=lob&page%5Bnumber%5D=2&page%5Bsize%5D=1",
          first: "https://api.example.com/v1/servers?bob=lob&page%5Bnumber%5D=1&page%5Bsize%5D=1",
          prev: "https://api.example.com/v1/servers?bob=lob&page%5Bnumber%5D=1&page%5Bsize%5D=1",
          next: "https://api.example.com/v1/servers?bob=lob&page%5Bnumber%5D=3&page%5Bsize%5D=1",
        }
      }.to_json
    }

    it { expect(build_json_for(collection, original_params: '?page%5Bnumber%5D=2&page%5Bsize%5D=1&bob=lob')).to eq(response_json) }
  end

  context 'non_counted resources work' do
    let(:collection) { NonCountable.new }
    let(:response_json) {
      {
        links: {
          self: "https://api.example.com/v1/servers?bob=lob&page%5Bnumber%5D=2&page%5Bsize%5D=1",
          first: "https://api.example.com/v1/servers?bob=lob&page%5Bnumber%5D=1&page%5Bsize%5D=1",
          prev: "https://api.example.com/v1/servers?bob=lob&page%5Bnumber%5D=1&page%5Bsize%5D=1",
          next: "https://api.example.com/v1/servers?bob=lob&page%5Bnumber%5D=3&page%5Bsize%5D=1",
        }
      }.to_json
    }

    it { expect(build_non_counted_json_for(collection, original_params: '?page%5Bnumber%5D=2&page%5Bsize%5D=1&bob=lob')).to eq(response_json) }
  end

  def build_non_counted_json_for(collection, options = {})
    Jbuilder.encode do |json|
      json.links do
        json.pages_no_count! collection,
                    url: "https://api.example.com/v1/servers" + options.fetch(:original_params, ''),
                    query_parameters: options.fetch(:query_parameters, {})
      end
    end
  end

  def build_json_for(collection, options = {})
    Jbuilder.encode do |json|
      json.links do
        json.pages! collection,
                    url: "https://api.example.com/v1/servers" + options.fetch(:original_params, ''),
                    query_parameters: options.fetch(:query_parameters, {})
      end
    end
  end

  def build_bad_json_for(collection)
    Jbuilder.encode do |json|
      json.links do
        json.pages! collection,
                    url: "https://api.example.com/v1/servers",
                    query_parameters: nil
      end
    end
  end

  def build_more_bad_json_for(collection)
    Jbuilder.encode do |json|
      json.links do
        json.pages! collection,
                    url: "https://api.example.com/v1/servers",
                    query_parameters: { some_key: nil }
      end
    end
  end
end

class NonCountable
  def current_page
    2
  end

  def size
    1
  end

  def total_pages
    raise "Nope"
  end
end
