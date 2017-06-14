function [frameNr,sRx, sRy, sRz] = getBestFrameNr(Rx, Ry, Rz, angleDeg)

%     measure = abs(Rx) + abs(Ry) + abs(Rz);
    measure = abs(Ry - deg2rad(angleDeg));% + abs(Rz);
    [~, frameNr] = min(measure);
    sRx = Rx(frameNr);
    sRy = Ry(frameNr);
    sRz = Rz(frameNr);
end