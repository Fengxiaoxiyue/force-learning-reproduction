function result = run_figure8_mocap(cfg, run_path, walk_path)
%RUN_FIGURE8_MOCAP Scaled Figure 1B network for running/walking channels.

[run_motion, labels] = preprocess_mocap_motion(run_path, 95);
[walk_motion, ~] = preprocess_mocap_motion(walk_path, 95);
max_frames = 1800;
run_motion = run_motion(1:min(max_frames,end),:);
walk_motion = walk_motion(1:min(max_frames,end),:);
rng(cfg.seed,'twister'); N=cfg.N; NF=cfg.NF; D=95;
Mgg=full(sprandn(N,N,cfg.p))*cfg.g/sqrt(cfg.p*N);
Mff=randn(NF,NF)*1.5/sqrt(NF); Jgf=randn(N,NF)*2/sqrt(NF); Jfg=zeros(NF,N);
Win=randn(N,2)/sqrt(2); W=zeros(N,D); P=eye(N)/cfg.alpha;
x=0.5*randn(N,1); y=0.5*randn(NF,1); r=tanh(x); s=tanh(y);
motions={run_motion,walk_motion};

for epoch=1:3
 for m=1:2
  target=motions{m}; control=zeros(2,1); control(m)=0.25;
  for ti=1:size(target,1)
   x=(1-cfg.dt)*x+cfg.dt*(Mgg*r+Jgf*s+Win*control);
   y=(1-cfg.dt)*y+cfg.dt*(Mff*s+Jfg*r); r=tanh(x); s=tanh(y); z=W'*r;
   if mod(ti,cfg.learn_every)==0
    k=P*r; c=1/(1+r'*k); P=P-k*(k'*c); e=z-target(ti,:)';
    dW=-(k*c)*e'; W=W+dW;
    for a=1:NF
      channel=mod(a-1,D)+1; Jfg(a,:)=Jfg(a,:)+dW(:,channel)';
    end
   end
  end
 end
end

outputs=cell(2,1); metrics=zeros(2,2);
for m=1:2
 target=motions{m}; control=zeros(2,1); control(m)=0.25; out=zeros(size(target));
 for ti=1:size(target,1)
  x=(1-cfg.dt)*x+cfg.dt*(Mgg*r+Jgf*s+Win*control);
  y=(1-cfg.dt)*y+cfg.dt*(Mff*s+Jfg*r); r=tanh(x); s=tanh(y); out(ti,:)=W'*r;
 end
 outputs{m}=out; metrics(m,1)=mean(abs(out-target),'all');
 metrics(m,2)=corr(out(:),target(:));
end
result=struct('targets',{motions},'outputs',{outputs},'metrics',metrics,'labels',{labels},'cfg',cfg);
save(fullfile(cfg.dataDir,'figure8_mocap.mat'),'result','-v7.3');
fig=figure('Visible','off','Color','w','Position',[100 100 1000 600]);
motion_names={'running','walking'};
for m=1:2
 subplot(2,1,m); plot(motions{m}(:,1:8)); hold on; plot(outputs{m}(:,1:8),'--'); hold off; grid on;
 title(sprintf('%s: first 8 of 95 channels',motion_names{m}));
end
exportgraphics(fig,fullfile(cfg.figureDir,'figure8_mocap.png'),'Resolution',200);
exportgraphics(fig,fullfile(cfg.figureDir,'figure8_mocap.pdf'),'ContentType','vector'); close(fig);
end
