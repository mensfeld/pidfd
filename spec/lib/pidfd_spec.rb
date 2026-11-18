# frozen_string_literal: true

RSpec.describe Pidfd do
  let(:pidfd) { nil }

  after do
    pidfd&.signal("KILL")
    pidfd&.cleanup
  end

  context "when checking if supported" do
    it "returns false on unsupported platforms" do
      if RUBY_DESCRIPTION.include?("darwin")
        expect(described_class.supported?).to be(false)
      else
        expect(described_class.supported?).to be(true)
      end
    end
  end

  context "when on unsupported platform", if: RUBY_DESCRIPTION.include?("darwin") do
    it "raises error when trying to create pidfd" do
      expect { described_class.new(Process.pid) }.to raise_error(Pidfd::Errors::PidfdOpenFailedError)
    end
  end

  context "when on supported platform", unless: RUBY_DESCRIPTION.include?("darwin") do
    context "when fork is already dead" do
      subject(:pidfd) { described_class.new(fork { nil }) }

      # Give the fork time to die
      before do
        pidfd
        sleep(0.5)
      end

      it { expect(pidfd.alive?).to be(false) }
      it { expect(pidfd.signal("TERM")).to be(false) }
      it { expect { pidfd.cleanup }.not_to raise_error }
    end

    context "when fork is alive and we decide to kill it" do
      subject(:pidfd) { described_class.new(fork { sleep(60) }) }

      before { pidfd }

      it { expect(pidfd.alive?).to be(true) }
      it { expect(pidfd.signal("TERM")).to be(true) }

      context "when fork was killed by us" do
        before do
          pidfd.signal("KILL")
          sleep(0.5)
        end

        it { expect(pidfd.alive?).to be(false) }
      end
    end

    context "when cleaning up a fork that is still alive" do
      subject(:pidfd) { described_class.new(pid) }

      let(:pid) { fork { sleep(1) } }

      before { pidfd }

      it "does not block other threads while waiting" do
        ticks = []
        ticker = Thread.new do
          loop do
            ticks << Process.clock_gettime(Process::CLOCK_MONOTONIC)
            sleep(0.05)
          end
        end

        sleep(0.1)
        Thread.new { pidfd.cleanup }.join
        ticker.kill
        ticker.join

        expect(ticks.each_cons(2).map { |a, b| b - a }.max).to be < 0.5
      end

      context "when a trapped signal arrives during the wait" do
        let(:previous_handler) { trap("CHLD") { nil } }

        before { previous_handler }

        after { trap("CHLD", previous_handler) }

        it "waits for the fork to exit and reaps it" do
          started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          other = fork { sleep(0.2) }

          pidfd.cleanup

          expect(Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at).to be >= 0.9
          expect { Process.waitpid(pid, Process::WNOHANG) }.to raise_error(Errno::ECHILD)
        ensure
          Process.wait(other)
        end
      end
    end

    context "when the fork was already reaped elsewhere" do
      # Not named pidfd, so the outer after hook does not call cleanup again when this one fails
      subject(:reaped) { described_class.new(pid) }

      let(:pid) { fork { nil } }

      before do
        reaped
        Process.wait(pid)
      end

      it "finishes the cleanup" do
        expect(Timeout.timeout(5) { reaped.cleanup }).to be(true)
        expect(reaped.alive?).to be(false)
      end
    end

    context "when we try to clean an already cleaned fork" do
      subject(:pidfd) { described_class.new(fork { nil }) }

      before do
        pidfd
        sleep(0.5)
        pidfd.cleanup
      end

      it { expect { pidfd.cleanup }.not_to raise_error }
    end

    context "when we try to send a signal to an already cleaned fork" do
      subject(:pidfd) { described_class.new(fork { nil }) }

      before do
        pidfd
        sleep(0.5)
        pidfd.cleanup
        # Fake being alive to simulate a race condition
        # note: since we do not signal after cleanup, this will not affect the execution
        allow(IO).to receive(:select).and_return(nil)
      end

      it { expect(pidfd.signal("TERM")).to be(false) }
    end

    context "when we could not open a pid" do
      it { expect { described_class.new(0) }.to raise_error(Pidfd::Errors::PidfdOpenFailedError) }
    end
  end
end
