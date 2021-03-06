function out = fast_task_main(seeds, varargin)

% Run a Free ASsociation Task. This has two mode, 'practice' and 'test' mode. 
%
% :Usage:
% ::
%
%    out = fast_task_main(seed, varargin)
%
%
% :Inputs:
%
%   **seeds:**
%        One word in each cell array, e.g., seeds = {'나무', '가방'};
%
%
% :Optional Inputs: Enter keyword followed by variable with values
%
%   **'practice':**
%        This mode plays only 5 beeps, and do not record the responses.
%
%   **'repeat':**
%        You can specify the number of repeats.
%
%   **'test' (default):**
%        This mode plays 40 beeps, and save an audio recording of the responses.
%
%   **'eye', 'eyetrack':**
%        This will turn on the eye tracker, and record eye movement and pupil size. 
%
%   **'biopac':**
%        This will send the trigger to biopac. 
%
%   **'savedir':**
%        You can specify the directory where you save the data.
%        The default is the /data of the current directory.
%
%   **'psychtoolbox':**
%        You can specify the psychtoolbox directory. 
%
%   **'savewav':**
%        You can choose to save or not to save wav files.
%
%   **'fmri':**
%        Run this experiment in the MRI
%
%
% :Output:
%
%   **out:**
%        recording audio file names in cell array
%
%
% :Examples:
% ::
%
%    seeds = {'나무', '가방'};
%    out = fast_task_main(seeds, 'repeat', 5); % repeat only 5 times
%    
%    out = fast_task_main(seeds, 'eye', 'biopac'); % test mode
%
%    out = fast_task_main(seeds, 'practice'); % practice mode (only 5 beeps)
%
% ..
%    Copyright (C) 2017 COCOAN lab
% ..
%
%    If you have any questions, please email to: 
%
%          Byeol Kim (roadndream@naver.com) or
%          Wani Woo (waniwoo@skku.edu)

%% default setting
testmode = false;
practice_mode = false;
USE_EYELINK = false;
USE_BIOPAC = false;
savewav = false;
savedir = fullfile(pwd, 'data');
response_repeat = 40;
start_line = 1;
out = [];
psychtoolboxdir = '/Users/admin/Dropbox/W_FAS_task/Psychtoolbox';
dofmri = false;

%% parsing varargin
for i = 1:length(varargin)
    if ischar(varargin{i})
        switch varargin{i}
            % functional commands
            case {'practice'}
                practice_mode = true;
            case {'eyetracker', 'eye', 'eyetrack'}
                USE_EYELINK = true;
            case {'biopac'}
                USE_BIOPAC = true;
                channel_n = 1;
                biopac_channel = 0;
                ljHandle = BIOPAC_setup(channel_n); % BIOPAC SETUP
            case {'test', 'testmode'}
                testmode = true;
            case {'savedir'}
                savedir = varargin{i+1};
            case {'repeat'}
                response_repeat = varargin{i+1};
            case {'psychtoolbox'}
                psychtoolboxdir = varargin{i+1};
            case {'savewav'}
                savewav = true;
            case {'fmri', 'dofmri'}
                dofmri = true;
            case {'seed_n'}
                seed_n = varargin{i+1};
        end
    end
end

%% SETUP: global
global theWindow W H; % window property
global white red orange bgcolor; % color
global window_rect; % rating scale

%% SETUP: Screen

addpath(genpath(psychtoolboxdir));

bgcolor = 100;

if testmode
    window_rect = [1 1 1280 800]; % in the test mode, use a little smaller screen
else
    window_rect = get(0, 'MonitorPositions'); % full screen
end

W = window_rect(3); % width of screen
H = window_rect(4); % height of screen
textH = H/2.3;

fontsize = 30;

white = 255;
red = [158 1 66];
orange = [255 164 0];

%% SETUP: DATA and Subject INFO

if ~practice_mode % if not practice mode, save the data
    
    [fname, start_line, SID] = subjectinfo_check(savedir, 'task'); % subfunction
    
    if exist(fname, 'file'), load(fname, 'out'); end
    
    % add some task information
    out.version = 'FAST_v2_10-12-2017';
    out.github = 'https://github.com/cocoanlab/fast_fmri';
    out.subject = SID;
    out.datafile = fname;
    out.starttime = datestr(clock, 0); % date-time
    
    % save the data
    save(out.datafile, 'out');
    
end

%% SETUP: Eyelink

% need to be revised when the eyelink is here.
if USE_EYELINK
    eyelink_main(data, 'Init');
    
    status = Eyelink('Initialize');
    if status
        error('Eyelink is not communicating with PC. Its okay baby.');
    end
    Eyelink('Command', 'set_idle_mode');
    WaitSecs(0.05);
end

%% TAST START: ===========================================================

try
    
    % START: Screen
    % whichScreen = max(Screen('Screens'));
	theWindow = Screen('OpenWindow', 0, bgcolor, window_rect); % start the screen
    Screen('Preference','TextEncodingLocale','ko_KR.UTF-8');
    font = 'NanumBarunGothic';
    Screen('TextFont', theWindow, font);
    Screen('TextSize', theWindow, fontsize);
    HideCursor;
    
    %% PROMPT SETUP:
    if dofmri
        ready_prompt = double('피험자가 준비되었으면, 이미징을 시작합니다 (s).');
    else
        ready_prompt = double('준비되셨으면 스페이스바를 눌러주세요.');
    end
    exp_start_prompt = double('실험자는 모든 것이 잘 준비되었는지 체크해주세요 (Biopac, Eyelink, 등등).\n모두 준비되었으면, 스페이스바를 눌러주세요.');
    run_end_prompt = double('잘하셨습니다. 다음 단어 세트를 기다려주세요.');
    exp_end_prompt = double('실험을 마치셨습니다. 감사합니다!');
    % -----
    
    if practice_mode
        response_repeat = 5;
    end
    
    % DEFINE SEED_LOOP
    if dofmri
        if ~exist('seed_n', 'var'), seed_loop = input('seed_n? '); 
        else, seed_loop = seed_n; end
    else
        seed_loop = start_line:numel(seeds); % loop for seed words
    end
    
    % DISPLAY EXP START MESSAGE
    while (1)
        [~,~,keyCode] = KbCheck;
        if keyCode(KbName('space'))==1
            break
        elseif keyCode(KbName('q'))==1
            abort_man;
        end
        Screen(theWindow,'FillRect',bgcolor, window_rect);
        DrawFormattedText(theWindow, exp_start_prompt, 'center', 'center', white, [], [], [], 1.5);
        Screen('Flip', theWindow);
    end
    
    
    %% MAIN PART of the experiment
    for seeds_n = seed_loop
        
        % show ready_prompt
        while (1)
            [~,~,keyCode] = KbCheck;
            
            if dofmri
                if keyCode(KbName('s'))==1
                    break
                elseif keyCode(KbName('q'))==1
                    abort_experiment('manual');
                end
            else
                if keyCode(KbName('space'))==1
                    break
                elseif keyCode(KbName('q'))==1
                    abort_experiment('manual');
                end
            end
            
            Screen(theWindow, 'FillRect', bgcolor, window_rect);
            DrawFormattedText(theWindow, ready_prompt,'center', textH, white);
            Screen('Flip', theWindow);
        end
        
        % FOR DISDAQ 10 SECONDS
        if dofmri
            % gap between 's' key push and the first stimuli (disdaqs: data.disdaq_sec)
            % 5 seconds: "시작합니다..."
            Screen(theWindow, 'FillRect', bgcolor, window_rect);
            DrawFormattedText(theWindow, double('시작합니다...'), 'center', 'center', white, [], [], [], 1.2);
            Screen('Flip', theWindow);
            out.dat{run_i}{tr_i}.runscan_starttime = GetSecs;
            WaitSecs(4);
            
            % 5 seconds: Blank
            Screen(theWindow,'FillRect',bgcolor, window_rect);
            Screen('Flip', theWindow);
            WaitSecs(4); % ADJUST THIS
        end
        
        if USE_EYELINK
            Eyelink('StartRecording');
            out.eyetracker_starttime = GetSecs; % eyelink timestamp
        end
    
    WaitSecs(0.1);
        
        Screen(theWindow, 'FillRect', bgcolor, window_rect);
        DrawFormattedText(theWindow, '+','center', textH, white);
        Screen('Flip', theWindow);
        WaitSecs(1);
        
        % Showing seed word, beeping, recording
        for response_n = 1:response_repeat
            
            if seeds_n == 1 && response_n == 1
                % Sound recording: Initialize
                InitializePsychSound;
                pahandle = PsychPortAudio('Open', [], 2, 0, 44100, 2);
            end
            
            % Sound recording: Preallocate an internal audio recording  buffer with a capacity of 10 seconds
            PsychPortAudio('GetAudioData', pahandle, 10);
            % start recording
            PsychPortAudio('Start', pahandle, 0, 0, 1);
            
            % seed word
            if response_n == 1
                
                % start timestamp
                if USE_BIOPAC, BIOPAC_trigger(ljHandle, biopac_channel, 'on'); end 
                out.starttime_getsecs{seeds_n} = GetSecs;
                
                Screen('FillRect', theWindow, bgcolor, window_rect);
                Screen('TextSize', theWindow, fontsize*1.2); % emphasize
                DrawFormattedText(theWindow, double(seeds{seeds_n}),'center', textH, orange);
                Screen('Flip', theWindow);
                Screen('TextSize', theWindow, fontsize);
                
                while true
                    if GetSecs - out.starttime_getsecs{seeds_n} >= 2.5 % Modify it
                        if USE_BIOPAC, BIOPAC_trigger(ljHandle, biopac_channel, 'off'); end 
                        break
                    end
                end
            end
            
            Screen('FillRect', theWindow, bgcolor, window_rect);
            Screen('Flip', theWindow);
            
            % beeping
            beep = MakeBeep(800,.15);
            Snd('Play',beep);
            out.beeptime_from_start{seeds_n}(response_n,1) = GetSecs-out.starttime_getsecs{seeds_n}; 
            
            % cross 
            Screen('FillRect', theWindow, bgcolor, window_rect);
            DrawFormattedText(theWindow, '+', 'center', textH, white);
            Screen('Flip', theWindow);
            waitsec_fromstarttime(out.beeptime_from_start{seeds_n}(response_n,1), 1)
            
            % blank
            Screen('FillRect', theWindow, bgcolor, window_rect);
            Screen('Flip', theWindow);
            waitsec_fromstarttime(out.beeptime_from_start{seeds_n}(response_n,1), 2.5)
            
            % stop recording
            PsychPortAudio('Stop', pahandle);
            out.audiodata{seeds_n}{response_n} = PsychPortAudio('GetAudioData', pahandle);
        end
        
        % Run End
        if seeds_n < numel(seeds)
            Screen(theWindow, 'FillRect', bgcolor, window_rect);
            DrawFormattedText(theWindow, run_end_prompt, 'center', textH, white);
            Screen('Flip', theWindow);
        end
        
        % save data
        if ~practice_mode
            out.response{seeds_n}{1} = seeds{seeds_n};
            save(out.datafile, 'out');
        end
        
        WaitSecs(1.0);
                
    end
    
    %% Close the audio device:
    
    PsychPortAudio('Close', pahandle);
    
    if ~practice_mode && savewav 
        [wavedir, wavefname] = fileparts(fname);
        for i = 1:numel(out.audiodata)
            wave_savename = fullfile(wavedir, [wavefname '_seed' num2str(i) '.wav']);
            audiowrite(wave_savename,cat(2,out.audiodata{i}{:})',44100);
        end
    end
    
    %% Experiment end message
    
    Screen(theWindow, 'FillRect', bgcolor, window_rect);
    DrawFormattedText(theWindow, exp_end_prompt, 'center', textH, white);
    Screen('Flip', theWindow);
    WaitSecs(2);
    
    ShowCursor; %unhide mouse
    Screen('CloseAll'); %relinquish screen control
    
catch err
    % ERROR 
    disp(err);
    for i = 1:numel(err.stack)
        disp(err.stack(i));
    end
    abort_experiment('error'); 
end

end



%% == SUBFUNCTIONS ==============================================

function display_runmessage(run_i, run_num, dofmri)

% MESSAGE FOR EACH RUN

% HERE: YOU CAN ADD MESSAGES FOR EACH RUN USING RUN_NUM and RUN_I

global theWindow white bgcolor window_rect; % rating scale

if dofmri
    if run_i <= run_num % you can customize the run start message using run_num and run_i
        Run_start_text = double('피험자가 준비되었으면, 이미징을 시작합니다 (s).');
    end
else
    if run_i <= run_num
        Run_start_text = double('피험자가 준비되었으면, r을 눌러 주세요.');
    end
end

% display
Screen(theWindow,'FillRect',bgcolor, window_rect);
DrawFormattedText(theWindow, Run_start_text, 'center', 'center', white, [], [], [], 1.5);
Screen('Flip', theWindow);

end

function display_runending_message(run_i, run_num)

global theWindow window_rect white bgcolor; % color

% MESSAGE FOR EACH RUN

% HERE: YOU CAN ADD MESSAGES FOR EACH RUN

if run_i < run_num
    Run_end_text = double([num2str(run_i) '번 세션을 마쳤습니다.\n피험자가 다음 세션을 진행할 준비가 되면, 스페이스바를 눌러주세요.']);
else
    Run_end_text = double('실험의 이번 파트를 마쳤습니다.\n프로그램에서 나가기 위해서는, 스페이스바를 눌러주세요.');
end
    
Screen(theWindow,'FillRect',bgcolor, window_rect);
DrawFormattedText(theWindow, Run_end_text, 'center', 'center', white, [], [], [], 1.5);
Screen('Flip', theWindow);

end


function abort_experiment(varargin)

% ABORT the experiment
%
% abort_experiment(varargin)

str = 'Experiment aborted.';

for i = 1:length(varargin)
    if ischar(varargin{i})
        switch varargin{i}
            % functional commands
            case {'error'}
                str = 'Experiment aborted by error.';
            case {'manual'}
                str = 'Experiment aborted by the experimenter.';
        end
    end
end


ShowCursor; %unhide mouse
Screen('CloseAll'); %relinquish screen control
disp(str); %present this text in command window

end