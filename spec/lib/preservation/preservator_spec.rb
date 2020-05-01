describe Preservation::Preservator do
  include_context 'tmp_assets'

  before(:each) do
    # FactoryBot.create(:sound) calls preserve, which calls create_moab_dirs
    # Call preserve explicitly when needed in this context
    allow_any_instance_of(
      Preservation::Preservator
    ).to receive(:preserve).and_return(true)
    @object = FactoryBot.create(:sound)
    @object[:status] = "draft"
    @object.save
    @preservator = Preservation::Preservator.new(@object)

    @target_path = @preservator.manifest_path(
      @preservator.object.id, 
      @preservator.version
    )    
    @err_string = "The Moab directory #{@target_path} for "\
      "#{@preservator.object.id} version #{@preservator.version} "\
      "already exists"
  end

  after(:each) do
    @object.delete
  end

  describe 'create_moab_dirs' do
    context 'when the moab dir already exists' do
      before do
        allow(File).to receive(:directory?).and_call_original
        allow(File).to receive(:directory?).with(@target_path).and_return(true)
      end
      it 'should raise an exception' do
        expect { @preservator.create_moab_dirs }.to raise_error(
          DRI::Exceptions::InternalError,
          @err_string
        )
      end
    end
    context 'when the moab directory does not exist' do
      before do
        allow(File).to receive(:directory?).and_call_original
        allow(File).to receive(:directory?).with(@target_path).and_return(false)
      end
      it 'should create the moab directory' do
        expect(@preservator).to receive(:make_dir)
        expect { @preservator.create_moab_dirs }.not_to raise_error
      end
    end
  end
end
