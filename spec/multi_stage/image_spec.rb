require 'spec_helper'
require 'multi_stage/image'
module MultiStage
  describe Image do
    describe ".affine" do
      subject { image.affine(:pixs2world) }
      let(:image){ Image.load(imageinfo_path) }
      let(:image_path){ 'tmp/chitech.tif'}
      let(:imageinfo_path){ 'tmp/chitech.geo'}

      before(:each) do
        setup_file(image_path)
        setup_file(imageinfo_path)
      end

      it {expect{ subject }.not_to raise_error}
    end

    describe ".from_sem_info" do
      let(:from_sem_info) { Image.from_sem_info(txt_path,stage2vs,opts)}
      let(:stage2vs){ [[1,0,0],[0,1,0],[0,0,1]] }
      let(:txt_path){ 'tmp/site-5-1.txt' }
      let(:opts){ {} }

      before(:each) do
        setup_file(txt_path)
      end

      context "with chitech" do
        it "returns instance of Image" do
          from_sem_info.should be_an_instance_of(Image)
        end
      end
    end
  end
end