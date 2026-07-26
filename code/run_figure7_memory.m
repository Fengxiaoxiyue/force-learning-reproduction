function result = run_figure7_memory(cfg)
%RUN_FIGURE7_MEMORY Four outputs controlled by eight ON/OFF pulse inputs.

rng(cfg.seed, 'twister');
N=cfg.N; bits=4; inputs=8;
M=randn(N,N)*cfg.g/sqrt(N); Win=randn(N,inputs)/sqrt(inputs);
W=zeros(N,bits); P=eye(N)/cfg.alpha; x=0.5*randn(N,1); r=tanh(x);
groups=reshape(1:(floor(N/bits)*bits),[],bits)';
train_steps=20000; pulse_every=100; pulse_width=10;
active_input=0;

for ti=1:train_steps
    u=zeros(inputs,1);
    if mod(ti-1,pulse_every)==0
        bit=randi(bits); on=rand>0.5; u(2*bit-1+double(~on))=0.375;
        active_input=2*bit-1+double(~on);
        if ti==1, state=-ones(bits,1); end
        state(bit)=2*on-1;
    elseif mod(ti-1,pulse_every)<pulse_width
        u(active_input)=0.375;
    end
    x=(1-cfg.dt)*x+cfg.dt*(M*r+Win*u); r=tanh(x); z=W'*r;
    if mod(ti,cfg.learn_every)==0
        k=P*r; c=1/(1+r'*k); P=P-k*(k'*c);
        for b=1:bits
            dw=-(z(b)-state(b))*k*c; W(:,b)=W(:,b)+dw;
            idx=groups(b,:); M(idx,:)=M(idx,:)+repmat(dw',numel(idx),1);
        end
    end
end

test_steps=2400; states=zeros(bits,test_steps); outputs=zeros(bits,test_steps); pulses=zeros(inputs,test_steps);
state=-ones(bits,1);
active_input=0;
for ti=1:test_steps
    u=zeros(inputs,1);
    if mod(ti-1,pulse_every)==0
        bit=mod(floor((ti-1)/pulse_every),bits)+1; on=mod(floor((ti-1)/pulse_every),2)==0;
        active_input=2*bit-1+double(~on); u(active_input)=0.375; state(bit)=2*on-1;
    elseif mod(ti-1,pulse_every)<pulse_width
        u(active_input)=0.375;
    end
    x=(1-cfg.dt)*x+cfg.dt*(M*r+Win*u); r=tanh(x); z=W'*r;
    states(:,ti)=state; outputs(:,ti)=z; pulses(:,ti)=u;
end
accuracy=mean(sign(outputs)==states,'all');
result=struct('states',states,'outputs',outputs,'pulses',pulses,'accuracy',accuracy,'cfg',cfg);
save(fullfile(cfg.dataDir,'figure7_memory.mat'),'result','-v7.3');
fig=figure('Visible','off','Color','w','Position',[100 100 1000 650]);
for b=1:bits
 subplot(bits,1,b); plot(states(b,:),'g','LineWidth',1.2); hold on; plot(outputs(b,:),'r'); hold off; ylim([-1.5 1.5]); grid on; ylabel(sprintf('bit %d',b));
end
exportgraphics(fig,fullfile(cfg.figureDir,'figure7_memory.png'),'Resolution',200);
exportgraphics(fig,fullfile(cfg.figureDir,'figure7_memory.pdf'),'ContentType','vector'); close(fig);
end
