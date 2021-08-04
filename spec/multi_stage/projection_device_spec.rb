require 'spec_helper'
require 'multi_stage'

module MultiStage
	describe ProjectionDevice do
		let(:cui){ ProjectionDevice.new(myout, args) }
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
			let(:args){ [ image_path ] }
			let(:image_path) { 'tmp/mis_A.jpg' }
			before(:each) do
                setup_empty_dir('tmp')
				setup_file(image_path)
			end
			it "not raise error" do
				expect{subject}.not_to raise_error
			end
        end

		describe "#run with invalid path", :current => true do
			subject { cui.run }
			let(:args){ [ image_path ] }
			let(:image_path) { 'tmp/mis_A.jpg' }
			before(:each) do
                setup_empty_dir('tmp')
			end
			it "raise error" do
				expect{subject}.to raise_error
			end
        end

		describe "#run with existing info" do
			subject { cui.run }
			let(:args){ [ image_path ] }
			let(:image_path) { 'tmp/mis_A.jpg' }
			let(:txt_path) { 'tmp/mis_A.txt' }
            before(:each) do
                setup_empty_dir('tmp')
				setup_file(image_path)
                setup_file(txt_path)
			end
			it "raise error" do
				expect{subject}.to raise_error
			end
        end

        describe "#run with magnification option" do
                subject { cui.run }
                let(:args){ [ image_path, '-x', magnification] }
                let(:image_path) { 'tmp/mis_A.jpg' }
                let(:magnification){ '150' }
                before(:each) do
                    setup_empty_dir('tmp')
                    setup_file(image_path)
                end
                it "not raise error" do
                    expect{subject}.not_to raise_error
                end
        end    

        describe "#run with width option", :current => true do
                subject { cui.run }
                let(:args){ [ image_path, '-w', width] }
                let(:image_path) { 'tmp/mis_A.jpg' }
                let(:width){ '10' }
                before(:each) do
                    setup_empty_dir('tmp')
                    setup_file(image_path)
                end
                it "not raise error" do
                    expect{subject}.not_to raise_error
                end
        end    

        describe "#run with matrix option" do
            subject { cui.run }
            let(:args){ [ image_path, '-p', position_string] }
            let(:image_path) { 'tmp/mis_A.jpg' }
            let(:position_string){ '2044,704,10200' }
            before(:each) do
                setup_empty_dir('tmp')
                setup_file(image_path)
            end
            it "not raise error" do
                expect{subject}.not_to raise_error
            end
        end    
    end
end