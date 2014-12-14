require 'unit_spec_helper'

describe Shoulda::Matchers::Independent::DelegateMethodMatcher do
  describe '#description' do
    context 'when the subject is an instance' do
      subject { Object.new }

      context 'without any qualifiers' do
        it 'states that it should delegate method to the right object' do
          matcher = delegate_method(:method_name).to(:delegate)
          message = 'delegate #method_name to #delegate object'

          expect(matcher.description).to eq message
        end
      end

      context 'qualified with #as' do
        it 'states that it should delegate method to the right object and method' do
          matcher = delegate_method(:method_name).to(:delegate).as(:alternate)
          message = 'delegate #method_name to #delegate object as #alternate'

          expect(matcher.description).to eq message
        end
      end

      context 'qualified with #with_arguments' do
        it 'states that it should delegate method to the right object with right argument' do
          matcher = delegate_method(:method_name).to(:delegate).
            with_arguments(:foo, bar: [1, 2])
          message = 'delegate #method_name to #delegate object passing arguments [:foo, {:bar=>[1, 2]}]'

          expect(matcher.description).to eq message
        end
      end
    end

    context 'when the subject is a class' do
      subject { Object }

      context 'without any qualifiers' do
        it 'states that it should delegate method to the right object' do
          matcher = delegate_method(:method_name).to(:delegate)

          expect(matcher.description).
            to eq 'delegate .method_name to .delegate object'
        end
      end

      context 'qualified with #as' do
        it 'states that it should delegate method to the right object and method' do
          matcher = delegate_method(:method_name).to(:delegate).as(:alternate)
          message = 'delegate .method_name to .delegate object as .alternate'

          expect(matcher.description).to eq message
        end
      end

      context 'qualified with #with_arguments' do
        it 'states that it should delegate method to the right object with right argument' do
          matcher = delegate_method(:method_name).to(:delegate).
            with_arguments(:foo, bar: [1, 2])
          message = 'delegate .method_name to .delegate object passing arguments [:foo, {:bar=>[1, 2]}]'

          expect(matcher.description).to eq message
        end
      end
    end
  end

  it 'raises an error if the delegate object was never specified before matching' do
    expect {
      expect(Object.new).to delegate_method(:name)
    }.to raise_error described_class::DelegateObjectNotSpecified
  end

  context 'stubbing a delegating method on an instance' do
    it 'only happens temporarily and is removed after the match' do
      define_class('Company') do
        def name
          'Acme Company'
        end
      end

      define_class('Person') do
        def company_name
          company.name
        end

        def company
          Company.new
        end
      end

      person = Person.new
      matcher = delegate_method(:company_name).to(:company).as(:name)
      matcher.matches?(person)

      expect(person.company.name).to eq 'Acme Company'
    end
  end

  context 'when the subject does not delegate anything' do
    before do
      define_class('PostOffice')
    end

    context 'when the subject is an instance' do
      it 'rejects with the correct failure message' do
        post_office = PostOffice.new
        message = [
          'Expected PostOffice to delegate #deliver_mail to #mailman object',
          'Method calls sent to PostOffice#mailman: (none)'
        ].join("\n")

        expect {
          expect(post_office).to delegate_method(:deliver_mail).to(:mailman)
        }.to fail_with_message(message)
      end
    end

    context 'when the subject is a class' do
      it 'uses the proper syntax for class methods in errors' do
        message = [
          'Expected PostOffice to delegate .deliver_mail to .mailman object',
          'Method calls sent to PostOffice.mailman: (none)'
        ].join("\n")

        expect {
          expect(PostOffice).to delegate_method(:deliver_mail).to(:mailman)
        }.to fail_with_message(message)
      end
    end
  end

  context 'when the subject delegates correctly' do
    before do
      define_class('Mailman')

      define_class('PostOffice') do
        def deliver_mail
          mailman.deliver_mail
        end

        def mailman
          Mailman.new
        end
      end
    end

    it 'accepts' do
      post_office = PostOffice.new
      expect(post_office).to delegate_method(:deliver_mail).to(:mailman)
    end

    context 'negating the matcher' do
      it 'rejects with the correct failure message' do
        post_office = PostOffice.new
        message = 'Expected PostOffice not to delegate #deliver_mail to #mailman object, but it did'

        expect {
          expect(post_office).not_to delegate_method(:deliver_mail).to(:mailman)
        }.to fail_with_message(message)
      end
    end
  end

  context 'when the delegating method is private' do
    before do
      define_class('Mailman')

      define_class('PostOffice') do
        def deliver_mail
          mailman.deliver_mail
        end

        def mailman
          Mailman.new
        end

        private :mailman
      end
    end

    it 'accepts' do
      post_office = PostOffice.new
      expect(post_office).to delegate_method(:deliver_mail).to(:mailman)
    end
  end

  context 'qualified with #with_arguments' do
    before do
      define_class('Mailman')

      define_class('PostOffice') do
        def deliver_mail(*args)
          mailman.deliver_mail('221B Baker St.', hastily: true)
        end

        def mailman
          Mailman.new
        end
      end
    end

    context 'qualified with #with_arguments' do
      context 'when the subject delegates with matching arguments' do
        it 'accepts' do
          post_office = PostOffice.new
          expect(post_office).to delegate_method(:deliver_mail).
            to(:mailman).with_arguments('221B Baker St.', hastily: true)
        end

        context 'negating the matcher' do
          it 'rejects with the correct failure message' do
            post_office = PostOffice.new
            message = 'Expected PostOffice not to delegate #deliver_mail to #mailman object passing arguments ["221B Baker St.", {:hastily=>true}], but it did'

            expect {
              expect(post_office).
                not_to delegate_method(:deliver_mail).
                to(:mailman).
                with_arguments('221B Baker St.', hastily: true)
            }.to fail_with_message(message)
          end
        end
      end

      context 'when not given the correct arguments' do
        it 'rejects with the correct failure message' do
          post_office = PostOffice.new
          message = [
            'Expected PostOffice to delegate #deliver_mail to #mailman object passing arguments ["123 Nowhere Ln."]',
            'Method calls sent to PostOffice#mailman:',
            '1) deliver_mail("221B Baker St.", {:hastily=>true})'
          ].join("\n")

          expect {
            expect(post_office).to delegate_method(:deliver_mail).
              to(:mailman).with_arguments('123 Nowhere Ln.')
          }.to fail_with_message(message)
        end
      end
    end
  end

  context 'qualified with #as' do
    before do
      define_class(:mailman)

      define_class(:post_office) do
        def deliver_mail
          mailman.deliver_mail_and_avoid_dogs
        end

        def mailman
          Mailman.new
        end
      end
    end

    context "when the subject's delegating method is the same as the one given to #as" do
      it 'accepts' do
        post_office = PostOffice.new
        expect(post_office).to delegate_method(:deliver_mail).
          to(:mailman).as(:deliver_mail_and_avoid_dogs)
      end

      context 'negating the assertion' do
        it 'rejects with the correct failure message' do
          post_office = PostOffice.new
          message = 'Expected PostOffice not to delegate #deliver_mail to #mailman object as #deliver_mail_and_avoid_dogs, but it did'

          expect {
            expect(post_office).
              not_to delegate_method(:deliver_mail).
              to(:mailman).
              as(:deliver_mail_and_avoid_dogs)
          }.to fail_with_message(message)
        end
      end
    end

    context "when the method given to #as does not exist" do
      it 'rejects with the correct failure message' do
        post_office = PostOffice.new
        message = [
          'Expected PostOffice to delegate #deliver_mail to #mailman object as #watch_tv',
          'Method calls sent to PostOffice#mailman:',
          '1) deliver_mail_and_avoid_dogs()'
        ].join("\n")

        expect {
          expect(post_office).to delegate_method(:deliver_mail).
            to(:mailman).as(:watch_tv)
        }.to fail_with_message(message)
      end
    end
  end
end
