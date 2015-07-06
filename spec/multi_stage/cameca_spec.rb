require 'spec_helper'
require 'multi_stage/cameca'
module MultiStage::Cameca
	describe TEST do
		it { expect(TEST.new).not_to be_nil }
	end

	describe DefChain do
    # h["filename"] = point["Name"] + ".is"
    # h["instr_file"] = point["Name"] + ".pri"
    # h["sple_name"] = point["Name"].split('@')[0]
    # h["sple_pos_x"] = point["X-Locate"].round
    # h["sple_pos_y"] = point["Y-Locate"].round
    	subject { def_chain.assign(input) }
    	let(:def_chain){ DefChain.new }
		let(:input){ {"tab" => [{"filename" => "test.is", "instr_file" => "test.pri", "sple_name" => "stone-1", "sple_pos_x" => 2, "sple_pos_y" => 3}]} }
		it {expect{ subject }.not_to raise_error}
	end
end