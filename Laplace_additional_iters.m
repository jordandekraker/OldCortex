clear; close all;

hdr = niftiinfo('Laplace_radial.nii.gz');
LBL = niftiread('labelmap-postProc.nii.gz');

%%
Laplace_tangential = niftiread('Laplace_tangential.nii.gz');
Laplace_tangential = Laplace_tangential(LBL>0);
for i = 1:10    
    [Laplace_tangential,iter_change_tangential] = laplace_solver(LBL>0,LBL==7,LBL==8,100,Laplace_tangential);
    disp(iter_change_tangential);
    LP = zeros(size(LBL)); LP(LBL>0) = Laplace_tangential;
    niftiwrite(LP,sprintf('Laplace_tangential_%02d', i),hdr,'compressed',true); % save checkpoints
end


%%

Laplace_radial = niftiread('Laplace_radial.nii.gz');
Laplace_radial = Laplace_radial(LBL>0);
for i = 1:10    
    [Laplace_radial,iter_change_radial] = laplace_solver(LBL>0,LBL==5,LBL==6,100,Laplace_radial);
    disp(iter_change_radial);
    LP = zeros(size(LBL)); LP(LBL>0) = Laplace_radial;
    niftiwrite(LP,sprintf('Laplace_radial_%02d', i),hdr,'compressed',true); % save checkpoints
end
