clear all;clc;

img = imread('cross_dimmed.png');
imgNew = img;

initColor = reshape(255*[1 1 1],1,1,3);
newColor = reshape([54 54 54],1,1,3);
BGColor = reshape([0 0 0],1,1,3);

for i = 1:size(img,1)
    for j = 1:size(img,2)     
%         if isequal(img(i,j,:), initColor)
        if ~isequal(img(i,j,:), BGColor)
            imgNew(i,j,:) = newColor;
        end
    end
end

imwrite(imgNew,'crossGrey.png');


imgNew = img;

newColor = reshape(255*[1 1 0],1,1,3);


for i = 1:size(img,1)
    for j = 1:size(img,2)     
%         if isequal(img(i,j,:), initColor)
        if ~isequal(img(i,j,:), BGColor)
            imgNew(i,j,:) = newColor;
        end
    end
end
imwrite(imgNew,'crossYellow.png');


img = imread('space_dimmed.png');
imgNew = img;

initColor = reshape(255*[1 1 1],1,1,3);
newColor = reshape([54 54 54],1,1,3);


for i = 1:size(img,1)
    for j = 1:size(img,2)     
%         if isequal(img(i,j,:), initColor)
        if ~isequal(img(i,j,:), BGColor)
            imgNew(i,j,:) = newColor;
        end
    end
end

imwrite(imgNew,'spaceGrey.png');


imgNew = img;

newColor = reshape(255*[1 1 0],1,1,3);


for i = 1:size(img,1)
    for j = 1:size(img,2)     
%         if isequal(img(i,j,:), initColor)
        if ~isequal(img(i,j,:), BGColor)
            imgNew(i,j,:) = newColor;
        end
    end
end
imwrite(imgNew,'spaceYellow.png');
