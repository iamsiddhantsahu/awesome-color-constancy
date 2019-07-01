function xandytouandv(my_x,my_y, u, v)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

uv_0 = -1.421875;
bin_size = 1 / 64;

my_u = round((u(my_x, my_y) - uv_0) / bin_size); 
my_v = round((v(my_x, my_y) - uv_0) / bin_size); 
my_u = max(min(my_u, 256), 1); 
my_v = max(min(my_v, 256), 1);

fprintf('u = %s\n',num2str(my_u));
fprintf('v = %s\n',num2str(my_v));

end

