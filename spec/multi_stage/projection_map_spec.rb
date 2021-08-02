require 'spec_helper'
require 'multi_stage'

module MultiStage
	describe ProjectionMap do
		let(:cui){ ProjectionMap.new(myout, args) }

		describe "#run with -h" do
			let(:args){ ['-h'] }

			it "shows help" do
				expect{cui.run}.to raise_error(SystemExit)
			end
		end


		describe "#run without path" do
			let(:args){ [] }
			it "raise_error" do
				expect{cui.run}.to raise_error(SystemExit)
			end
		end


		describe "#run with path" do
			subject { cui.run }
			let(:args){ [ txt_path ] }
			let(:txt_path) { 'tmp/site-5-1.txt' }
			before(:each) do
				setup_file(txt_path)
			end
			it "not raise error" do
				expect{subject}.not_to raise_error
			end
    end

    describe "#run with affinefile option" do
			subject { cui.run }
			let(:args){ [ txt_path, '-a', affine_path] }
			let(:txt_path) { 'tmp/site-5-1.txt' }
      let(:affine_path){ 'tmp/device.geo' }
			before(:each) do
				setup_file(txt_path)
        setup_file(affine_path)
			end
			it "not raise error" do
				expect{subject}.not_to raise_error
			end
    end    

		describe "#run with matrix option" do
			subject { cui.run }
			let(:args){ [ txt_path, '-m', matrix_string] }
			let(:txt_path) { 'tmp/site-5-1.txt' }
      let(:matrix_string){ '10,0,0,0,10,0,0,0,1' }
			before(:each) do
				setup_file(txt_path)
			end
			it "not raise error" do
				expect{subject}.not_to raise_error
			end
    end    
  end
end