
function legBasis(chan::Channel, legK, loopIdx)
    KinL, KoutL, KinR, KoutR = legK[1], legK[2], legK[3], legK[4]
    K = zero(KinL)
    K[loopIdx] = 1
    if chan == T
        Kx = KoutL + K - KinL
        LLegK = [KinL, KoutL, Kx, K]
        RLegK = [K, Kx, KinR, KoutR]
    elseif chan == U
        Kx = KoutR + K - KinL
        LLegK = [KinL, KoutR, Kx, K]
        RLegK = [K, Kx, KinR, KoutL]
    elseif chan == S
        Kx = KinL + KinR - K
        LLegK = [KinL, Kx, KinR, K]
        RLegK = [K, KoutL, Kx, KoutR]
    else
        error("not implemented!")
    end

    # check conservation and momentum assignment
    @assert LLegK[INL] ≈ KinL
    @assert LLegK[INL] + LLegK[INR] ≈ LLegK[OUTL] + LLegK[OUTR]
    @assert RLegK[INL] + RLegK[INR] ≈ RLegK[OUTL] + RLegK[OUTR]

    return LLegK, K, RLegK, Kx
end

function tauBasis(chan::Channel, LvT, RvT)
    G0T = (LvT[OUTR], RvT[INL])
    if chan == T
        extT = (LvT[INL], LvT[OUTL], RvT[INR], RvT[OUTR])
        GxT = (RvT[OUTL], LvT[INR])
    elseif chan == U
        extT = (LvT[INL], RvT[OUTR], RvT[INR], LvT[OUTL])
        GxT = (RvT[OUTL], LvT[INR])
    elseif chan == S
        extT = (LvT[INL], RvT[OUTL], LvT[INR], RvT[OUTR])
        GxT = (LvT[OUTL], RvT[INR])
    else
        error("not implemented!")
    end

    # make sure all tidx are used once and only once
    t1 = sort(vcat(collect(G0T), collect(GxT), collect(extT)))
    t2 = sort(vcat(collect(LvT), collect(RvT)))
    @assert t1 == t2 "chan $(chan): G0=$G0T, Gx=$GxT, external=$extT don't match with Lver4 $LvT and Rver4 $RvT"
    @assert extT[INL] == LvT[INL]
    return extT, G0T, GxT
end

function legBasis(chan::TwoBodyChannel, legK, loopIdx)
    KinL, KoutL, KinR, KoutR = legK[1], legK[2], legK[3], legK[4]
    K = zero(KinL)
    K[loopIdx] = 1
    if chan == PHr
        Kx = KoutL + K - KinL
        LLegK = [KinL, KoutL, Kx, K]
        RLegK = [K, Kx, KinR, KoutR]
    elseif chan == PHEr
        Kx = KoutR + K - KinL
        LLegK = [KinL, KoutR, Kx, K]
        RLegK = [K, Kx, KinR, KoutL]
    elseif chan == PPr
        Kx = KinL + KinR - K
        LLegK = [KinL, Kx, KinR, K]
        RLegK = [K, KoutL, Kx, KoutR]
    else
        error("not implemented!")
    end

    # check conservation and momentum assignment
    @assert LLegK[INL] ≈ KinL
    @assert LLegK[INL] + LLegK[INR] ≈ LLegK[OUTL] + LLegK[OUTR]
    @assert RLegK[INL] + RLegK[INR] ≈ RLegK[OUTL] + RLegK[OUTR]

    return LLegK, K, RLegK, Kx
end

function tauBasis(chan::TwoBodyChannel, LvT, RvT)
    G0T = (LvT[OUTR], RvT[INL])
    if chan == PHr
        extT = (LvT[INL], LvT[OUTL], RvT[INR], RvT[OUTR])
        GxT = (RvT[OUTL], LvT[INR])
    elseif chan == PHEr
        extT = (LvT[INL], RvT[OUTR], RvT[INR], LvT[OUTL])
        GxT = (RvT[OUTL], LvT[INR])
    elseif chan == PPr
        extT = (LvT[INL], RvT[OUTL], LvT[INR], RvT[OUTR])
        GxT = (LvT[OUTL], RvT[INR])
    else
        error("not implemented!")
    end

    # make sure all tidx are used once and only once
    t1 = sort(vcat(collect(G0T), collect(GxT), collect(extT)))
    t2 = sort(vcat(collect(LvT), collect(RvT)))
    @assert t1 == t2 "chan $(chan): G0=$G0T, Gx=$GxT, external=$extT don't match with Lver4 $LvT and Rver4 $RvT"
    @assert extT[INL] == LvT[INL]
    return extT, G0T, GxT
end


function factor(para, chan)
    Factor = SymFactor[Int(chan)] / (2π)^para.loopDim
    if para.isFermi == false
        Factor = abs(Factor)
    end
    return Factor
end

function typeMap(ltype, rtype)
    if (ltype == Instant || ltype == Dynamic) && (rtype == Instant || rtype == Dynamic)
        return Dynamic
    elseif (ltype == D_Instant || ltype == D_Dynamic) && (rtype == Instant || rtype == Dynamic)
        return D_Dynamic
    elseif (ltype == Instant || ltype == Dynamic) && (rtype == D_Instant || rtype == D_Dynamic)
        return D_Dynamic
    else
        return nothing
    end
end