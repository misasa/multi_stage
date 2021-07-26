require 'spec_helper'
require 'multi_stage'
module MultiStage
	describe WarpSpots do
		let(:cui){ WarpSpots.new(myout, args) }

		describe "array_to_matrix" do
			subject{ cui.array_to_matrix(array) } 
			let(:args){ [] }
			let(:array){[[1,0,0],[0,1,0],[0,0,1]]}
			it {
				expect(subject).to be_an_instance_of(Matrix)
			}
		end
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
			let(:txt_path) { 'tmp/vs-points-list.txt' }
			before(:each) do
				setup_file(txt_path)
			end

			it "not raise error" do
				expect{subject}.not_to raise_error
			end

			context "format txt" do
				let(:args){ [ txt_path, "-f", "txt" ]}
				it {
					subject
				}
			end

			context "format csv" do
				let(:args){ [ txt_path, "-f", "csv" ]}
				it {
					subject
				}
			end

			context "format yaml" do
				let(:args){ [ txt_path, "-f", "yaml" ]}
				it {
					subject
				}
			end

			context "format cha", :current => true do
				let(:args){ [ txt_path, "-f", "cha" ]}
				it {
                                  expect{subject}.to raise_error
				}
			end

			context "format reflist", :current => true do
				let(:args){ [ txt_path, "-f", "reflist" ]}
				it {
                                  expect{subject}.to raise_error
				}
			end


			context "format org" do
				let(:args){ [ txt_path, "-f", "org" ]}
				it {
					subject
				}
			end

			context "format tex" do
				let(:args){ [ txt_path, "-f", "tex", "-g", image_path, "-a", imageinfo_path ]}
				let(:image_path){ 'tmp/chitech.tif'}
				let(:imageinfo_path){ 'tmp/chitech.geo'}

				before(:each) do
					setup_file(image_path)
					setup_file(imageinfo_path)					
				end

				it {
					subject
				}
			end

			context "output yaml" do
				let(:args){ [ txt_path, "-o", out_path ]}
				let(:out_path){ "tmp/vs-points-list.yaml" }
				it {
					subject
					expect(File.exists?(out_path)).to be_truthy
				}
			end

			context "output cha", :current => true do
				let(:args){ [ txt_path, "-o", out_path ]}
				let(:out_path){ "tmp/vs-points-list.cha" }
				it {
                                        expect{subject}.to raise_error
				}
			end

			context "output reflist", :current => true do
				let(:args){ [ txt_path, "-o", out_path ]}
				let(:out_path){ "tmp/vs-points-list.reflist" }
				it {
                                        expect{subject}.to raise_error
				}
			end

		end
	end
end
