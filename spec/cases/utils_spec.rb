describe Koala::Utils do
  it "has a deprecate method" do
    Koala::Utils.should respond_to(:deprecate)
  end

  # AFAIK there's no way to test that (Kernel.)warn receives the text
  # Kernel.should_receive(:warn) doesn't seem to work, even though the text gets printed
end