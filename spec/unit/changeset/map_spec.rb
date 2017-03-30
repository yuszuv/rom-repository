RSpec.describe ROM::Changeset, '.map' do
  context 'single mapping with transaction DSL' do
    subject(:changeset) do
      Class.new(ROM::Changeset::Create[:users]) do
        map do
          unwrap :address
          rename_keys street: :address_street, city: :address_city, country: :address_country
        end

        def default_command_type
          :test
        end
      end.new(relation, __data__: user_data)
    end

    let(:relation) { double(:relation) }

    context 'with a hash' do
      let(:user_data) do
        { name: 'Jane', address: { street: 'Street 1', city: 'NYC', country: 'US' } }
      end

      it 'sets up custom data pipe' do
        expect(changeset.to_h)
          .to eql(name: 'Jane', address_street: 'Street 1', address_city: 'NYC', address_country: 'US' )
      end
    end

    context 'with an array' do
      let(:user_data) do
        [{ name: 'Jane', address: { street: 'Street 1', city: 'NYC', country: 'US' } },
         { name: 'Joe', address: { street: 'Street 2', city: 'KRK', country: 'PL' } }]
      end

      it 'sets up custom data pipe' do
        expect(changeset.to_a)
          .to eql([
                    { name: 'Jane', address_street: 'Street 1', address_city: 'NYC', address_country: 'US' },
                    { name: 'Joe', address_street: 'Street 2', address_city: 'KRK', address_country: 'PL' }
                  ])
      end
    end
  end

  context 'multi mapping with custom blocks' do
    subject(:changeset) do
      Class.new(ROM::Changeset::Create[:users]) do
        map do |tuple|
          tuple.merge(one: next_value)
        end

        map do |tuple|
          tuple.merge(two: next_value)
        end

        def initialize(*args)
          super
          @counter = 0
        end

        def default_command_type
          :test
        end

        def next_value
          @counter += 1
        end
      end.new(relation).data(user_data)
    end

    let(:relation) { double(:relation) }
    let(:user_data) { { name: 'Jane' } }

    it 'applies mappings in order of definition' do
      expect(changeset.to_h).to eql(name: 'Jane', one: 1, two: 2)
    end

    it 'inherits pipes' do
      klass = Class.new(changeset.class)

      expect(klass.pipes).to eql(changeset.class.pipes)
    end
  end

  context 'injecting dependencies to custom blocks' do
    let(:relation) { double(:relation) }
    let(:user_data) { { name: 'Jane' } }

    it 'works after initialization with optional dependencies' do
      changeset = Class.new(ROM::Changeset::Create[:users]) do
        option :dep, reader: true, optional: true

        map do |tuple|
          tuple.merge(dep: dep)
        end
      end.new(relation).with(dep: "foo").data(user_data)

      expect(changeset.to_h).to eql(name: 'Jane', dep: 'foo')
    end

    it 'works on initialization' do
      changeset = Class.new(ROM::Changeset::Create[:users]) do
        option :dep, reader: true

        map do |tuple|
          tuple.merge(dep: dep)
        end
      end.new(relation, dep: "foo").data(user_data)

      expect(changeset.to_h).to eql(name: 'Jane', dep: 'foo')
    end
  end
end
