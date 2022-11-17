require_relative '../source/lambda_function'

RSpec.describe LambdaFunction do
  let(:event) do
    { 'player_name' => 'steph-curry' }
  end

  describe '#call' do
    context 'when event is missing' do
      it 'raises an error' do
        expect {
          lambda_handler(event: nil, context: nil)
        }.to raise_error("The 'player_name' key in the event payload is required")
      end
    end

    context 'when event is missing "player_name" key' do
      let(:event) do
        { 'foo' => 'bar' }
      end

      it 'raises an error' do
        expect {
          lambda_handler(event: event, context: nil)
        }.to raise_error("The 'player_name' key in the event payload is required")
      end
    end

    context 'when player game log URL cannot be found' do
      let(:event) do
        { 'player_name' => 'michael-jordan' }
      end

      it 'raises an error' do
        expect {
          lambda_handler(event: event, context: nil)
        }.to raise_error("Cannot find the game log URL for 'michael-jordan'")
      end
    end

    context 'when event is valid' do
      before do
        expect(HTTParty).to receive(:get).once.and_return(page_source)
      end

      context 'and player stats cannot be found' do
        let(:page_source) { '<html><body></body></html>' }

        it 'returns false' do
          expect(lambda_handler(event: event, context: nil)).to eq(false)
        end
      end

      context 'and player stats are empty' do
        let(:page_source) { File.read('spec/fixtures/player_page_without_stats.html') }

        it 'returns an array without stats' do
          res = lambda_handler(event: event, context: nil)
          expect(res).to be_kind_of(Array)
          expect(res).to be_empty
        end
      end

      context 'and player stats are found' do
        let(:page_source) { File.read('spec/fixtures/player_page_with_stats.html') }

        it 'returns an array with stats' do
          res = lambda_handler(event: event, context: nil)
          expect(res).to be_kind_of(Array)
          expect(res.count).to eq(3)

          aggregate_failures 'results' do
            expect(res[0]).to eq({
              'date' => 'Nov 3, 2022',
              'opponent' => '@ORL',
              '3fga' => '15',
              '3fgm' => '8'
            })

            expect(res[1]).to eq({
              'date' => 'Oct 23, 2022',
              'opponent' => 'vs SAC',
              '3fga' => '12',
              '3fgm' => '7'
            })

            expect(res[2]).to eq({
              'date' => 'Oct 18, 2022',
              'opponent' => 'vs LAL',
              '3fga' => '13',
              '3fgm' => '4'
            })
          end
        end
      end
    end
  end
end
