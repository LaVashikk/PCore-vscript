// More info here: https://gizma.com/easing/

math["ease"] <- {}
local ease = math["ease"]

ease["InSine"] <- function(t) { 
    return 1 - cos((t * PI) / 2);
}

ease["OutSine"] <- function(t) { 
    return sin((t * PI) / 2);
}

ease["InOutSine"] <- function(t) { 
    return -(cos(PI * t) - 1) / 2;
}

ease["InQuad"] <- function(t) { 
    return t * t; 
}

ease["OutQuad"] <- function(t) { 
    return 1 - (1 - t) * (1 - t); 
}

ease["InOutQuad"] <- function(t) { 
    return t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2;
}

ease["InCubic"] <- function(t) { 
    return t * t * t;
}

ease["OutCubic"] <- function(t) { 
    return 1 - pow(1 - t, 3);
}

ease["InOutCubic"] <- function(t) { 
    return t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2;
}

ease["InQuart"] <- function(t) {
    return t * t * t * t; 
}

ease["OutQuart"] <- function(t) { 
    return 1 - pow(1 - t, 4);
}

ease["InOutQuart"] <- function(t) { 
    return t < 0.5 ? 8 * t * t * t * t : 1 - pow(-2 * t + 2, 4) / 2;
}

ease["InQuint"] <- function(t) { 
    return t * t * t * t * t;
}

ease["OutQuint"] <- function(t) { 
    return 1 - pow(1 - t, 5);
}

ease["InOutQuint"] <- function(t) { 
    return t < 0.5 ? 16 * t * t * t * t * t : 1 - pow(-2 * t + 2, 5) / 2;
}

ease["InExpo"] <- function(t) { 
    return t == 0 ? 0 : pow(2, 10 * t - 10);
}

ease["OutExpo"] <- function(t) { 
    return t == 1 ? 1 : 1 - pow(2, -10 * t);
}

ease["InOutExpo"] <- function(t) { 
    return t == 0 ? 0 : t == 1 ? 1 : t < 0.5 ? pow(2, 20 * t - 10) / 2 : (2 - pow(2, -20 * t + 10)) / 2;
}

ease["InCirc"] <- function(t) { 
    return 1 - sqrt(1 - pow(t, 2));
}

ease["OutCirc"] <- function(t) { 
    return sqrt(1 - pow(t - 1, 2));
}

ease["InOutCirc"] <- function(t) { 
    return t < 0.5 ? (1 - sqrt(1 - pow(2 * t, 2))) / 2 : (sqrt(1 - pow(-2 * t + 2, 2)) + 1) / 2;
}

ease["InBack"] <- function(t) { 
    local c1 = 1.70158;
    local c3 = c1 + 1;
    return c3 * t * t * t - c1 * t * t;
}

ease["OutBack"] <- function(t) { 
    local c1 = 1.70158;
    local c3 = c1 + 1;
    return 1 + c3 * pow(t - 1, 3) + c1 * pow(t - 1, 2);
}

ease["InOutBack"] <- function(t) { 
    local c1 = 1.70158;
    local c2 = c1 * 1.525;
    return t < 0.5
       ? (pow(2 * t, 2) * ((c2 + 1) * 2 * t - c2)) / 2
       : (pow(2 * t - 2, 2) * ((c2 + 1) * (t * 2 - 2) + c2) + 2) / 2;
}

ease["InElastic"] <- function(t) { 
    local c4 = (2 * PI) / 3;
    return t == 0
        ? 0
        : t == 1
        ? 1
        : -pow(2, 10 * t - 10) * sin((t * 10 - 10.75) * c4);
}

ease["OutElastic"] <- function(t) { 
    local c4 = (2 * PI) / 3;
    return t == 0
    ? 0
    : t == 1
    ? 1
    : pow(2, -10 * t) * sin((t * 10 - 0.75) * c4) + 1;
}

ease["InOutElastic"] <- function(t) { 
    local c5 = (2 * PI) / 4.5;
    return t == 0
    ? 0
    : t == 1
    ? 1
    : t < 0.5
    ? -(pow(2, 20 * t - 10) * sin((20 * t - 11.125) * c5)) / 2
    : (pow(2, -20 * t + 10) * sin((20 * t - 11.125) * c5)) / 2 + 1;
}

ease["InBounce"] <- function(t) { 
    return 1 - math.ease.OutBounce(1 - t);
}

ease["OutBounce"] <- function(t) { 
    local n1 = 7.5625;
    local d1 = 2.75;
    if (t < 1 / d1) {
    return n1 * t * t;
    } else if (t < 2 / d1) {
        return n1 * (t -= 1.5 / d1) * t + 0.75;
    } else if (t < 2.5 / d1) {
        return n1 * (t -= 2.25 / d1) * t + 0.9375;
    } else {
        return n1 * (t -= 2.625 / d1) * t + 0.984375;
    }
}

ease["InOutBounce"] <- function(t) { 
    return t < 0.5
    ? (1 - math.ease.OutBounce(1 - 2 * t)) / 2
    : (1 + math.ease.OutBounce(2 * t - 1)) / 2;
}