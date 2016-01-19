function outputVideo = stabilizeVideo(video, optFlow)
% Stabilizes video with opticalFlowFunc.
% Input: - video: NxMxK matrix where NxM is the size of the frames and K is
%                 the total amount of frames.
%        - optFlow: optical flow estimation for every pair of frames.
    
    outputVideo = zeros(size(video),'like',video);
    
    % Define similarity matrix (scale, rotation, translation)
    simMatrix = @(tx, ty, theta, s) [s*cos(theta)  s*-sin(theta) 0;
                                     s*sin(theta)  s*cos(theta)  0;
                                     tx            ty            1];
    
    outputVideo(:,:,1) = video(:,:,1);
    % Matrix that will define the transformation from a frame t+1 to a
    % frame t
    tform = affine2d(eye(3));
    for i = 1:length(optFlow) 
        % Note: opticalFlow{i} corresponds to the optFlow of frame i to
        % frame i+1
        tx = mode(optFlow{i}.Vx(:));
        ty = mode(optFlow{i}.Vy(:));
        %theta = mean(mean(optFlow{i}.Orientation));
        % Acumulate transformation in the transformation matrix so that
        % frame T is warped to frame 1.
        %NO FUNCIONA B� ENCARA. Crec que les coordenades del LK no s�n les
        %correctes. La theta tamb� �s molt exagerada, rota molt la imatge.
        tform.T = tform.T*simMatrix(-tx, -ty, 0, 1);
        % El imwarp retorna una imatge que pot ser de dimensions diferents
        % que l'outputVideo, s'ha de retallar
        Rinput = imref2d(size(video(:,:,i+1)));
        
        % Creem una imatge del tamany de la original pero amb RGB
        % R sera el video en escala de grisos original
        % G els valors omplerts
        % B es redundant
        imAux = zeros(size(video(:,:,i+1),1), size(video(:,:,i+1),2), 3);
        % Assignem la imatge original al canal R
        imAux(:,:,1) = video(:,:,i+1);
        % Apliquem el warp
        outputAux = imwarp(imAux, tform,'OutputView',Rinput, 'FillValues', [255; 255; 255]); %imwarp(video(:,:,i+1), tform,'OutputView',Rinput);
        
        % Definim novament els canals B els valors omplerts, R la imatge
        % original
        notFilledValues = outputAux(:,:,2);  
        imStabilizedAux = outputAux(:,:,1);
        
        % Mirem quins valors no s'han omplert
        ind = notFilledValues ~= 255;
        
        % apliquem a la imatge original els valors que NO s'han omplert de
        % forma que evitem que la imatge de sortida tingui "negre" i
        % conservi com a fons la imatge original.
        initialImage = video(:,:,i+1);
        initialImage(ind) = imStabilizedAux(ind);
        outputVideo(:,:,i+1) = initialImage;      
    end
end