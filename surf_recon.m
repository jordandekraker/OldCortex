% WIP. I am still not happy with these surface reconstruction methods. It may have to do with imperfect Laplace solutions.


clear; close all;
Laplace_radial = niftiread('Laplace_radial.nii.gz');
Laplace_tangential = niftiread('Laplace_tangential.nii.gz');
LBL = niftiread('labelmap-postProc.nii.gz');
hdr = niftiinfo('labelmap-postProc.nii.gz');

i = find(LBL>0);
sz = size(LBL);
[x,y,z] = ind2sub(sz,i);
Laplace_radial = Laplace_radial(i);
Laplace_tangential = Laplace_tangential(i);
LBL = LBL(i);



%% use cosine basis functions to describe concentric rings
% 
% interval = linspace(0,1,100);
%     
% figure('units','normalized','outerposition',[0 0 1 1])
% for band = 1:length(interval)-1
%     d = find(Laplace_radial>interval(band) & Laplace_radial<interval(band+1));
%     scatter3(x(d),y(d),z(d),1,Laplace_tangential(d),'.');
%     xlim([748, 1464]);
%     ylim([185, 1960]);
%     zlim([284, 1605]);
%     view(-90,0);
%     drawnow;
%     
%     %extract this 'band' and sort by tangential coords
%     [LP,i] = sort(Laplace_tangential(d));
%     v = [x(d(i)) y(d(i)) z(d(i))];
%     % make and fit a cosine basis design matrix with k cosine functions
%     for k = 1:10
%         DX(:,k) = cos(linspace(-pi*k,pi*k,length(v)));
%     end
%     beta = pinv(DX'*DX)*DX'*v;
%     % reconstruct pointcloud
%     vrec = DX*beta;
%     plot3(vrec(:,1),vrec(:,2),vrec(:,3));
% end

%% reduce points (averaging bins) to a meshgrid

longitudebins = 100;
latittudebins = 100;

longlin = linspace(0,1,longitudebins);
latlin = linspace(0,1,latittudebins);
grid = nan(longitudebins,latittudebins,3);
for long = 1:longitudebins-1
    for lat = 1:latittudebins-1
        vertices = find(Laplace_radial>longlin(long) & Laplace_radial<longlin(long+1) & ...
            Laplace_tangential>latlin(lat) & Laplace_tangential<latlin(lat+1));
        try
            grid(long,lat,1) = mean(x(vertices));
            grid(long,lat,2) = mean(y(vertices));
            grid(long,lat,3) = mean(z(vertices));
        end
    end
end
grid(:,end,:) = grid(:,1,:);
for dir = 1:3
    grid(:,:,dir) = fillmissing(grid(:,:,dir),'linear');
end

% get face connectivity
tri = [1:(longitudebins*latittudebins)]';
F = [tri,tri+1,tri+(longitudebins) ; tri,tri-1,tri-(longitudebins)];
F = reshape(F',[3,longitudebins,latittudebins,2]);
F(:,longitudebins,:,1) = nan;
F(:,1,:,2) = nan;
F(:,:,latittudebins,1) = nan;
F(:,:,1,2) = nan;
F(isnan(F)) = [];
F=reshape(F,[3,(longitudebins-1)*(latittudebins-1)*2])';

% save as gifti
gii = gifti();
gii.faces = F;
gii.vertices = reshape(grid,[100*100,3]);
gii.vertices(:,4) = 0;
gii.vertices = gii.vertices * hdr.Transform.T;
gii.vertices(:,4) = [];
gii.vertices = gii.vertices+hdr.Transform.T(4,1:3);
save(gii,'meshgrid-100x100.surf.gii','Base64Binary');

figure;
vertices = patch('faces',F,'vertices',reshape(grid,[100*100,3]));
vertices.LineStyle = 'none';
%p.FaceColor = 'b';
material dull;
light;
hold on;
c = jet(latittudebins);
for lat = 1:latittudebins-1
    plot3(grid(lat,:,1),grid(lat,:,2),grid(lat,:,3),'color',c(lat,:));
end
axis equal tight;
view(90,0);
saveas(gcf,'longitudinalLines-lat.png')
view(-90,0);
saveas(gcf,'longitudinalLines-med.png')

% try smoothing with cosineRep
% Vrecon = CosineRep_2Dsurf(grid,5,0.001);
% p = patch('faces',F,'vertices',Vrecon);
% p.LineStyle = 'none';
% p.FaceColor = 'b';
% material dull;
% light;
% hold on;
% axis equal tight;

%% reduce points to a meshgrid using interpolant
% see https://github.com/jordandekraker/Hippocampal_AutoTop/blob/master/tools/coords_SurfMap.m

lt = Laplace_tangential*2*pi - pi;
lr = 1-Laplace_radial;
[xx,yy] = pol2cart(lt,lr);

fd=@(p) sqrt(sum(p.^2,2)) -1;
[vertices,tri] = distmesh2d(fd,@huniform,0.01,[-1,-1;1,1],[]); % 36k vertices

scattInterp = scatteredInterpolant(xx,yy,x,'nearest','nearest');
xxx = scattInterp(vertices(:,1),vertices(:,2));
scattInterp = scatteredInterpolant(xx,yy,y,'nearest','nearest');
yyy = scattInterp(vertices(:,1),vertices(:,2));
scattInterp = scatteredInterpolant(xx,yy,z,'nearest','nearest');
zzz = scattInterp(vertices(:,1),vertices(:,2));
clear scattInterp;
Vxyz = [xxx yyy zzz];

figure;
p = patch('faces',tri,'vertices',Vxyz);
p.LineStyle = 'none';
p.FaceColor = 'b';
material dull;
light;
axis equal tight;

gii = gifti();
gii.faces = tri;
gii.vertices = Vxyz;
gii.vertices(:,4) = 0;
gii.vertices = gii.vertices * hdr.Transform.T;
gii.vertices(:,4) = [];
gii.vertices = gii.vertices+hdr.Transform.T(4,1:3);
save(gii,'distmesh-36k.surf.gii','Base64Binary');
gii.vertices = [vertices(:,1),vertices(:,2), zeros(length(vertices),1)];
save(gii,'distmesh-36k_unfolded.surf.gii','Base64Binary');

% smooth
FV = struct();
FV.faces = tri;
FV.vertices = Vxyz;
FV2 = smoothpatch(FV);

figure;
p = patch(FV2);
p.LineStyle = 'none';
p.FaceColor = 'b';
material dull;
light;
axis equal tight;

gii.vertices = FV2.vertices;
gii.vertices(:,4) = 0;
gii.vertices = gii.vertices * hdr.Transform.T;
gii.vertices(:,4) = [];
gii.vertices = gii.vertices+hdr.Transform.T(4,1:3);
save(gii,'distmesh-36k_smoothed.surf.gii','Base64Binary');

