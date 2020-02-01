clear;clc;close all;
img=imread('peacock.jpg');
img=im2double(img);
imshow(img)

u=log((img(:,:,2)+eps)./(img(:,:,1)+eps));

v=log((img(:,:,2)+eps)./(img(:,:,3)+eps));

uv_0 = -1.421875;
bin_size = 1 / 40;
bin_num = 256;
[h, w, ~] = size(u);
hist = zeros(256, 256); %initializing the histogram
% iterating over the entire image and plot the log chroma histogram
for i = 1:h 
    for j = 1:w  
        u_val = round((u(i, j) - uv_0) / bin_size); 
        v_val = round((v(i, j) - uv_0) / bin_size); 
        u_val = max(min(u_val, 256), 1); 
        v_val = max(min(v_val, 256), 1); %after this we know which bin to in
        hist(u_val, v_val) = hist(u_val, v_val) + 1; 
    end 
end 
hist = hist ./ sum(hist(:));


bins = -(0.0025 * (bin_num - 1))/2 + [0 : 0.0025 : (0.0025 * (bin_num - 1))];
imagesc(bins, bins, hist);
