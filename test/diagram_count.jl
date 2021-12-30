#see Ref. https://arxiv.org/pdf/cond-mat/0512342.pdf for details
# We assume:
# 1. interaction is spin-symmetric. 
# 2. the propagator conserves the spin.

function gamma3_g2v(innerLoopNum, spin)
    if innerLoopNum == 1
        return 1
    elseif innerLoopNum == 2
        return 3 * (2 + spin)
    elseif innerLoopNum == 3
        return 5 * (10 + 9 * spin + spin^2)
    else
        error("not implemented!")
    end
end

function gamma3_G2v(innerLoopNum, spin)
    if innerLoopNum == 1
        return 1
    elseif innerLoopNum == 2
        return 4 + 3 * spin
    elseif innerLoopNum == 3
        return 27 + 31 * spin + 5 * spin^2
    else
        error("not implemented!")
    end
end

function gamma3_G2W(innerLoopNum, spin)
    if innerLoopNum == 1
        return 1
    elseif innerLoopNum == 2
        return 4 + 2 * spin
    elseif innerLoopNum == 3
        return 27 + 22 * spin
    else
        error("not implemented!")
    end
end

function sigma_G2v(innerLoopNum, spin)
    if innerLoopNum == 1
        return 1
    elseif innerLoopNum == 2
        return 1 + spin
    elseif innerLoopNum == 3
        return 4 + 5 * spin + spin^2
    elseif innerLoopNum == 4
        return 27 + 40 * spin + 14 * spin^2 + spin^3
    else
        error("not implemented!")
    end
end

function sigma_G2W(innerLoopNum, spin)
    return gamma3_G2W(innerLoopNum, spin)
end

function polar_G2v(innerLoopNum, spin)
    return spin * gamma3_G2v(innerLoopNum, spin)
end

function polar_G2W(innerLoopNum, spin)
    return spin * gamma3_G2W(innerLoopNum, spin)
end