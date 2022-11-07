require_relative '../source/lambda_function'

RSpec.describe LambdaFunction do
  describe '#call' do
    before do
      expect(HTTParty).to receive(:get).once.and_return(page_source)
    end

    context 'when player stats cannot be found' do
      let(:page_source) { '<html><body></body></html>' }

      it 'returns false' do
        expect(lambda_handler(event: nil, context: nil)).to eq(false)
      end
    end

    context 'when player stats are empty' do
      let(:page_source) { File.read('spec/fixtures/player_page_without_stats.html') }

      it 'returns an array without stats' do
        res = lambda_handler(event: nil, context: nil)
        expect(res).to be_kind_of(Array)
        expect(res.count).to eq(1)
        expect(res[0]).to eq(%w(Date Opponent 3FGA 3FGM))
      end
    end

    context 'when player stats are found' do
      let(:page_source) { File.read('spec/fixtures/player_page_with_stats.html') }

      it 'returns an array with stats' do
        res = lambda_handler(event: nil, context: nil)
        expect(res).to be_kind_of(Array)

        aggregate_failures 'results' do
          expect(res[0]).to eq(%w(Date Opponent 3FGA 3FGM))
          expect(res[1]).to eq(['Nov 3, 2022', '@ORL', '15', '8'])
          expect(res[2]).to eq(['Oct 23, 2022', 'vs SAC', '12', '7'])
          expect(res[3]).to eq(['Oct 18, 2022', 'vs LAL', '13', '4'])
        end
      end
    end
  end
end
