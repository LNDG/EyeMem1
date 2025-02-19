function EM_pls_OAvsYA_setup()
% PLS-preprocess data and collect all subj on the cluster, cast them to local machine

fun2run = @EM_pls_OAvsYA;

if ismac
  basepath = '/Users/kloosterman/gridmaster2012/kloosterman/projectdata/eyemem/'; %yesno or 2afc
  %     backend = 'parfor';
  backend = 'local';
  %   backend = 'qsublocal';
  compile = 'no';
else
  basepath = '/mnt/beegfs/home/kloosterman/projectdata/eyemem/'; 
%   backend = 'slurm';
  backend = 'torque';
  %   backend = 'local';
  compile = 'no';
end
timreq = 10; %in minutes per run
memreq = 4000; % in MB

% analysis settings
nbins = 5; % no of bins used for Hmax binning
removeoutliers = false;
Z_thresh = 3; % if removeoutliers
do_kstest = 0;
PLStype = 'taskPLS'; % behavPLSvsdprime or taskPLS
% binsubtract = [5 1]; % which bins to subtract: % [5 1] is bin5-bin1
% binsubtract = [5 1; 4 1; 3 1; 5 3; 4 3]; % which bins to subtract: % [5 1] is bin5-bin1
binsubtract = 'linearfit';

load participantinfo.mat % TODO make this reliable

PREIN = fullfile(basepath, 'variability', 'ftsource');
% PREINeye = fullfile(basepath, 'preproc', 'eye');

overwrite = 1;
    
cd(PREIN);
subjlist = dir('source*.mat');

% SUBJ= [9, 11:59, 61:69, 71,72, 74:101]; % TODO specify further?

%make cells for each subject, to analyze in parallel
cfg = [];
cfg.PREIN = PREIN;
cfg.behavfile =  fullfile(basepath, 'preproc/behavior', 'Eyemem_behavior.mat');
cfg.PLStype = PLStype;
cfg.nbins = nbins;
cfg.removeoutliers = removeoutliers;
cfg.Z_thresh = Z_thresh;
cfg.do_kstest = do_kstest;
cfg.BOLDvar_measure = 'iqr'; % iqr, nanstd

cfglist = {};

for isub = 1:length(subjlist)
  tok = tokenize(subjlist(isub).name, '_');
  [~, subj] = fileparts(tok{2});
  cfg.subj = subj;
  for ibinsubtr = 1:size(binsubtract,1)
    cfg.binsubtract = binsubtract(ibinsubtr,:);
    if isnumeric(binsubtract)
      binsubtractfolder = sprintf('bin%d-bin%d', binsubtract(ibinsubtr,:));
    else
      binsubtractfolder = sprintf('linearfit');
    end
    BOLDvar_binsfolder = sprintf('%s_%dbins', cfg.BOLDvar_measure, nbins);
    
    agefolder = Participants(Participants.participant_id == subj, :);     % give different outfolder for OA and YA
    
    PREOUT = fullfile(basepath, 'variability', 'ftsource', PLStype, 'OAvsYA_IQR'); % 
    mkdir(PREOUT)
    mkdir(fullfile( PREOUT, 'source' ))
    cfg.PREOUT = PREOUT;

    cfg.sourcefile = fullfile(PREIN, subjlist(isub).name);

    cfg.outfile_source = fullfile(PREOUT, 'source', subjlist(isub).name); % binned source data to source folder
    
    cfg.outfile_sesdat = fullfile(PREOUT, [subj '_BfMRIsessiondata.mat']); % PLS _BfMRIsessiondata
    
    if ~exist(cfg.outfile_sesdat, 'file') || overwrite
      cfglist{end+1} = cfg;
    end
    if ~exist(fileparts(cfg.outfile_sesdat))
      mkdir(fileparts(cfg.outfile_sesdat))
    end
    
  end
end
% cfglist = cfglist(2)
% cfglist = cfglist(randsample(length(cfglist),length(cfglist)));

fprintf('Running %s for %d cfgs\n', mfilename, length(cfglist))

if strcmp(backend, 'slurm')
  options = '-D. -c1'; % --gres=gpu:1
else
  options =  '-l nodes=1:ppn=1'; % torque %-q testing or gpu
end

setenv('TORQUEHOME', 'yes')
mkdir('~/qsub'); cd('~/qsub');

if strcmp(backend, 'local')
  cellfun(fun2run, cfglist);
else
  qsubcellfun(fun2run, cfglist, 'memreq', memreq*1e6, 'timreq', timreq*60, 'stack', 1, ...
    'StopOnError', true, 'UniformOutput', true, 'backend', backend, 'options', options);
end

