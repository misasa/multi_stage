require 'spec_helper'
require 'multi_stage/image'
module MultiStage
	describe Image do
    	subject { image.affine(:pixs2world) }
    	let(:image){ Image.load(imageinfo_path) }
		let(:image_path){ 'tmp/chitech.tif'}
		let(:imageinfo_path){ 'tmp/chitech.vs'}

		before(:each) do
			setup_file(image_path)
			setup_file(imageinfo_path)
			#p image.corners_on_pixs
			#p subject				
		end

		it {expect{ subject }.not_to raise_error}
	end
end