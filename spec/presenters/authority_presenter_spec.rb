require 'rails_helper'

describe DRI::AuthorityPresenter do
  describe 'viewable_vocabs' do
    before do
      # only local authorities have the concept of being empty
      # remote authorities can be temporarily unreachable, but not empty
      @local_athoritiy_names = %w(Nuts3 Hasset)
      @local_athorities = @local_athoritiy_names.map do |name|
        Qa::Authorities.const_get(name)
      end
    end
    context 'when local vocabs are empty' do
      before do
        @local_athorities.each do |empty_authority|
          allow_any_instance_of(empty_authority).to receive(:empty?).and_return(true)
        end
      end
      it 'should remove empty authorities' do
        @local_athoritiy_names.each do |authority_name|
          visible_authority_names = subject.class.viewable_vocabs.map { |h| h[:name] }
          expect(visible_authority_names.include?(authority_name)).to be false
        end
      end
    end
    context 'when local vocabs are not empty' do
      before do
        @local_athorities.each do |empty_authority|
          allow_any_instance_of(empty_authority).to receive(:empty?).and_return(false)
        end
      end
      it 'should display all authorities' do
        @local_athoritiy_names.each do |authority_name|
          visible_authority_names = subject.class.viewable_vocabs.map { |h| h[:name] }
          expect(visible_authority_names.include?(authority_name)).to be true
        end
      end
    end
  end
end
