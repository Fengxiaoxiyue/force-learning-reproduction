# FORCE 论文复现：授课式流程

本文档解释本项目如何从论文图示建立模型、实现 FORCE/RLS、逐案运行实验并判断复现是否成功。所有命令均从项目根目录执行。

## 1. 先建立“案例—架构”映射

论文 Figure 1 给出三类架构：

- **Figure 1A**：生成网络的线性读出 `z(t)` 直接反馈到生成网络，只训练读出权重。
- **Figure 1B**：在生成网络和输出之间增加独立反馈网络，训练生成网络到反馈网络的连接。
- **Figure 1C**：把误差信号用于修改生成网络内部连接，使目标动力学内化。

本项目遵循论文中每个案例实际展示的架构。只有 Figure 2D 四正弦目标按事先确认的范围分别用 1A、1B、1C 实现。Figure 7A/7C 是输入协议示意，分别并入 Figure 7B/7D 的代码，不作为独立输出任务。

## 2. 连续模型与离散化

生成网络状态为 $x(t)$，神经元放电率为

$$
r(t)=\tanh(x(t)).
$$

Figure 1A 的线性读出为

$$
z(t)=w^\top r(t).
$$

把神经元时间常数归一化为 1 后，连续模型为

$$
\dot{x}=-x+Mr+w_fz.
$$

代码使用 Euler 离散化：

```text
x(t+dt) = (1-dt)x(t) + dt*M*r(t) + dt*wf*z(t)
r(t+dt) = tanh(x(t+dt))
```

随机递归矩阵非零元素的尺度为 $g/\sqrt{pN}$。`g>1` 时随机网络通常进入强烈、不规则的活动区间；FORCE 的任务不是先消除这些活动，而是在反馈环保持闭合时寻找能稳定目标轨道的权重。

## 3. Figure 2D 目标函数

补充 MATLAB 代码公开了四正弦目标：

$$
f(t)=\frac{a}{1.5}\left[
\sin(\pi qt)+\frac12\sin(2\pi qt)
+\frac16\sin(3\pi qt)+\frac13\sin(4\pi qt)
\right].
$$

默认 $a=1.3$、$q=1/60$。实现位于 `code/make_four_sine_target.m`。这是项目中最适合做正确性基准的案例，因为目标解析式和原始示例代码均可核对。

## 4. RLS/FORCE 更新逐步解释

在更新前先计算误差：

$$
e^-(t)=w^\top(t-\Delta t)r(t)-f(t).
$$

令 $P(0)=I/\alpha$，一次 RLS 更新为

$$
k=Pr,
\qquad
c=\frac{1}{1+r^\top k},
$$

$$
P\leftarrow P-kk^\top c,
\qquad
w\leftarrow w-e^-kc.
$$

理解这组公式时要抓住三点：

1. `P` 是活动相关矩阵的逆的递推估计，不是固定标量学习率。
2. `k=Pr` 根据历史活动调整当前更新方向。
3. FORCE 在反馈环闭合时更新；训练动力学和测试动力学之间不会突然换成另一套网络。

对应代码是 `code/rls_update.m`。把更新独立成函数后，可以单独测试维度、有限性以及 `P` 的近似对称性。

## 5. 如何逐案复现

### 5.1 先跑测试

```powershell
matlab -batch "run('tests/run_all_tests.m')"
```

测试覆盖目标长度、RLS 矩阵、固定种子重复性、PCA 历史数据、AMC 文件解析和非 RLS 学习率有限性。

### 5.2 Figure 2

```powershell
matlab -batch "run('scripts/run_figure2_suite.m')"
```

该脚本依次生成 2A--K，并对 2D 运行 1A、1B、1C。结果汇总在 `results/data/figure2_summary.csv`。

并非所有目标都能称为“精确复现”。Figure 2E 的 16 个系数、Figure 2G 的精确方波细节、Figure 2J 的一次性波形没有完整数值公开，因此代码返回 `exact=false` 并在 CSV 中记录说明。

### 5.3 Figures 3--5

```powershell
matlab -batch "run('scripts/run_figures3_to5.m')"
```

- Figure 3 保存神经元活动和权重历史，对中心化活动做 SVD，并用前 8 个主成分重构输出。
- Figure 4 在训练反馈中混合目标和网络输出，测试时始终闭合网络输出反馈，观察训练/测试反馈不匹配造成的失稳。
- Figure 5 使用配对随机种子扫描 `g`，比较达到误差阈值的周期数、测试 RMSE 和读出权重范数。

### 5.4 Figures 6--8

```powershell
matlab -batch "run('scripts/run_figures6_to8.m')"
```

- Figure 6A：延迟和非线性反馈，架构 1A。
- Figure 6B：独立反馈网络，架构 1B。
- Figure 6C：内部学习，架构 1C。
- Figure 7B：静态控制输入选择五种输出，架构 1C。
- Figure 7D：8 个 ON/OFF 脉冲控制 4 位记忆，架构 1C。
- Figure 8：CMU `09_02` 跑步和 `08_01` 走路，架构 1B。

Figure 8 预处理依次执行：删除 root 平移、角度转弧度并展开、5 帧移动平均、10 倍 PCHIP 插值、去均值、整理为 95 通道。原始文件来源和使用条款写在 `data/raw/mocap/README.md`。

### 5.5 Supplement S1--S2

```powershell
matlab -batch "run('scripts/run_supplement.m')"
```

S1 不使用 RLS，而使用

$$
w(t)=w(t-\Delta t)-\eta(t)e^-(t)r(t),
$$

$$
\dot{\eta}=\eta\left[-\eta+|e|^{3/2}\right]
$$

的归一化形式。训练时长使用补充材料报告的 $60,000\tau$。S2 计算

$$
J_{\mathrm{eff}}=gJ^{GG}+J^{Gz}w^\top
$$

在训练前后的特征值，并比较 `g=0.8` 与 `g=1.5`。

## 6. 如何判断成功、部分和失败

不能只看训练曲线。最低判断流程是：

1. **数值健康**：无 `NaN/Inf`，维度正确，脚本完整结束。
2. **训练跟随**：训练 MAE 足够小，但这只能证明在线更新压住了误差。
3. **冻结测试**：停止更新后继续闭环运行；周期目标检查 MAE 和相关系数。
4. **任务指标**：记忆使用位准确率，运动使用 95 通道总体相关，谱分析使用特征值迁移。
5. **目标真实性**：未公开数值的结构性目标不能宣称精确复现。
6. **规模一致性**：缩小网络失败不能直接否定论文的大规模结果。

Lorenz 等混沌目标还要特别处理：长期逐点误差会因为相位或初值微小差异迅速增长。后续应增加短期预测误差、功率谱、吸引子占据和分布指标。

## 7. 调参纪律

推荐顺序：

1. 固定随机种子和目标，只验证代码。
2. 固定 `N/g`，调整 `alpha` 和训练时长。
3. 固定 `alpha`，扫描 `g`，所有参数使用配对种子。
4. 最后增加 `N`、反馈网络大小和稀疏连接数。
5. 每次只改变一个主要因素，并保留失败 `.mat`。

`alpha` 越大，初始 `P=I/alpha` 越小，早期更新越保守。`N` 增大通常提高可用活动维度，但 RLS 的内存和计算成本约随 $N^2$ 增长；Figure 1B 还会增加每个反馈单元的学习矩阵成本。

## 8. 当前结果和下一步

成功或较强复现包括：Figure 2D 的 1A/1C、Figure 2G、Figure 3、Figure 5 趋势、Figure 6C、Figure 7D、Figure 8 和 S2。Figure 1B 四正弦、Figure 6A/6B、Figure 7B、慢正弦和 S1 冻结测试在当前缩放规模下未达到论文表现。

优先改进建议：

1. 在高内存机器上按论文规模运行 Figure 6B、7B、8 和 S1。
2. 为 Lorenz 增加混沌系统专用指标。
3. 获得原始目标文件后替换 Figure 2E/2J 的结构性波形。
4. 将 Figure 8 的 95 通道重新映射到骨架并输出动画。
5. 自动记录 MATLAB、CPU、RAM、BLAS 和运行时长。

## 9. 报告和版本管理

LaTeX 报告从 `results/figures` 直接引用图：

```powershell
cd report
latexmk -pdf -interaction=nonstopmode -halt-on-error main.tex
```

逐案提交摘要见根目录 README。主文 Zotero 条目 key 为 `D2YQS7LK`，导出的 BibTeX 位于 `report/bibliography/zotero.bib`。
