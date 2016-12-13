function [sensitivity]=SensitivityCalc(CantileverFile,frequency,LDV_amplitude,CantileverAmplitude)
load(CantileverFile)


% integrate velocity signal from the LDV
displacement=LDV_amplitude*0.01/(frequency*2*pi);

sensitivity=displacement/CantileverAmplitude;
save(CantileverFile)

end