function varargout = Img(varargin)
% IMG MATLAB code for img.fig
%      IMG, by itself, creates a new IMG or raises the existing
%      singleton*.
%
%      H = IMG returns the handle to a new IMG or the handle to
%      the existing singleton*.
%
%      IMG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IMG.M with the given input arguments.
%
%      IMG('Property','Value',...) creates a new IMG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before img_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to img_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help img

% Last Modified by GUIDE v2.5 01-Feb-2020 19:17:42

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @img_OpeningFcn, ...
                   'gui_OutputFcn',  @img_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before img is made visible.
function img_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to img (see VARARGIN)

% Choose default command line output for img
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes img wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = img_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global img

filename = 'D65_rightlamp.dng';
bayer_type = 'rggb';
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

% Define transformation matrix from sRGB space to XYZ space for later use
srgb2xyz = [0.4124564 0.3575761 0.1804375;
    0.2126729 0.7151522 0.0721750;
    0.0193339 0.1191920 0.9503041];

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% % % - - - - Reading DNG file from DNG Converter output - - - - % % %
    
% - - - Reading file - - -
warning off MATLAB:tifflib:TIFFReadDirectory:libraryWarning
t = Tiff(filename,'r');
offsets = getTag(t,'SubIFD');
setSubDirectory(t,offsets(1));
raw = read(t);
close(t);
meta_info = imfinfo(filename);
x_origin = meta_info.SubIFDs{1}.ActiveArea(2)+1;
width = meta_info.SubIFDs{1}.DefaultCropSize(1);
y_origin = meta_info.SubIFDs{1}.ActiveArea(1)+1;
height = meta_info.SubIFDs{1}.DefaultCropSize(2);
raw =double(raw(y_origin:y_origin+height-1,x_origin:x_origin+width-1));
    
% - - - Linearize - - -
if isfield(meta_info.SubIFDs{1},'LinearizationTable')
    ltab=meta_info.SubIFDs{1}.LinearizationTable;
    raw = ltab(raw+1);
end
black = meta_info.SubIFDs{1}.BlackLevel(1);
saturation = meta_info.SubIFDs{1}.WhiteLevel;
lin_bayer = (raw-black)/(saturation-black);
lin_bayer = max(0,min(lin_bayer,1));
clear raw

%{  
% - - - White Balance - - -
wb_multipliers = (meta_info.AsShotNeutral).^-1;
wb_multipliers = wb_multipliers/wb_multipliers(2);
mask = wbmask(height,width,wb_multipliers,bayer_type);
balanced_bayer = lin_bayer .* mask;
clear lin_bayer mask
%}

    
% - - - Color Correction Matrix from DNG Info - - -
temp = meta_info.ColorMatrix2;
xyz2cam = reshape(temp,3,3)';
 


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% % % - - - - - The rest of the processing chain - - - - -

% - - - Demosaicing - - -
temp = uint16(lin_bayer/max(lin_bayer(:))*2^16);
lin_rgb = single(demosaic(temp,bayer_type))/65535;
clear balanced_bayer temp

% - - - My Own White Balance - - - 
% ------------------------------------------------------------------------
illu_x = 754;
illu_y = 1997;
light_color = [lin_rgb(illu_x,illu_y,1), lin_rgb(illu_x,illu_y,2), lin_rgb(illu_x,illu_y,3)];
wb_mul = (light_color(:)/light_color(2)).^-1;
wb_ccm = [wb_mul(1) 0 0;
    0 wb_mul(2) 0;
    0 0 wb_mul(3)];
balanced_lin_bayer = apply_cmatrix(lin_rgb, wb_ccm);
balanced_lin_bayer = max(0,min(balanced_lin_bayer,1));
% -----------------------------------------------------------------------

% - - - These steps are only for viewing purposes - - -
% - - - Color Space Conversion - - -
rgb2cam = xyz2cam * srgb2xyz;
rgb2cam = rgb2cam ./ repmat(sum(rgb2cam,2),1,3);
cam2rgb = rgb2cam^-1;

lin_srgb = apply_cmatrix(balanced_lin_bayer,cam2rgb);
lin_srgb = max(0,min(lin_srgb,1));
%clear lin_rgb

% - - - Brightness and Gamma - - -
grayim = rgb2gray(lin_srgb);
grayscale = 0.25/mean(grayim(:));
bright_srgb = min(1,lin_srgb*grayscale);
clear lin_srgb grayim

nl_srgb = bright_srgb.^(1/2.2);


img=im2double(balanced_lin_bayer);
set(handles.axes1,'Units','pixels')
axes(handles.axes1)
A=imshow(nl_srgb);

u=log((img(:,:,2)+eps)./(img(:,:,1)+eps));

v=log((img(:,:,2)+eps)./(img(:,:,3)+eps));
global uv_0 
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

while(1)
    [u_val,v_val]=axes1_ButtonDownFcn(hObject, eventdata, handles);
    axes(handles.axes2)
    imagesc(bins, bins, hist);
    axes(handles.axes2)
    hold on
    plot(u_val,v_val,'r*')
    hold off
    axes(handles.axes1)
end


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over pushbutton1.
function pushbutton1_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on mouse press over axes background.
function[u_val,v_val]= axes1_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to axes1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
X=round(ginput(1))
global img
RGB=img(X(2),X(1),:);
u=log((RGB(2)+eps)./(RGB(1)+eps));
v=log((RGB(2)+eps)./(RGB(3)+eps));
global uv_0 
bin_size = 1 / 40;
bin_num = 256;
u_val = round((u - uv_0) / bin_size); 
v_val = round((v - uv_0) / bin_size); 
u_val = -(0.0025 * (bin_num - 1))/2 + 0.0025*(max(min(u_val, 256), 1)-1); 
v_val = -(0.0025 * (bin_num - 1))/2 + 0.0025*(max(min(v_val, 256), 1)-1);
