local Vec3 = Vector3.new
local Original = game.PlaceId == 455366377 and true


local DoorData = Original and {
    Doors = {
        Open = {
            Vec3(-953.3, 5, -178.7), Vec3(-953.3, 5, -165.1), Vec3(-187.7, 5.9, 163.9), Vec3(-59, 7.8, -315), Vec3(-43.8, 7.8, -324.4), Vec3(-85.8, 7.8, -302.1), Vec3(-29.4, 7.8, -296.5), Vec3(-243.2, 8, -30.5), Vec3(-275.4, 8, -45.9), Vec3(-111.7, 8.5, -101.6), Vec3(-106.2, 8.6, -126.2), Vec3(-121.6, 8.6, -94), Vec3(-122.1, 7.5, -404.6), Vec3(-137.5, 7.5, -372.4), Vec3(-132, 7.4, -397), Vec3(-759.7, 7.4, -102.3), Vec3(-155, 7.6, -350.4), Vec3(-791.3, 7.4, -142.7), Vec3(-186.6, 7.6, -390.8), Vec3(-203.4, 9.2, -19.2), Vec3(-171.8, 9.2, 21.1), Vec3(-24.1, 8.9, -63.2), Vec3(-64.6, 8.9, -31.6), Vec3(-249, 5.6, 125), Vec3(-287.5, 5.6, 128.9), Vec3(-837.5, 20.4, 116.3), Vec3(-837.5, 33.4, 116.7), Vec3(-837.5, 46.4, 115.7), Vec3(-821.1, 7.4, 95.4), Vec3(-628.7, 20.4, -22.2), Vec3(-628.3, 33.4, -22.2), Vec3(-629.3, 46.4, -22.2), Vec3(-649.5, 7.4, -38.5), Vec3(-983.1, 20.2, -52.1), Vec3(-983.5, 33.2, -52.1), Vec3(-982.5, 46.2, -52.1), Vec3(-962.3, 7.2, -35.8), Vec3(-27.6, 20.1, -501.5), Vec3(-27.6, 33.1, -501.9), Vec3(-27.6, 46.1, -500.9), Vec3(-44, 7, -480.8), Vec3(-646, 4.3, -341.6), Vec3(-187.7, 5.9, 130.9), Vec3(-50.4, 9, 9.6), Vec3(-53.6, 9, -108.2), Vec3(-996.6, 3.9, -85.7), Vec3(-544.9, -18.9, -108.3), Vec3(-38.4, 9, -117.6), Vec3(-499.7, 5.2, -52.7), Vec3(-994.7, 3.9, -71.2), Vec3(-957.8, 3.8, -83.3), Vec3(-197.8, 20, 146.9), Vec3(-170.9, 5.9, 132.1), Vec3(-42.8, 8.9, 19.5), Vec3(-80.4, 9, -95.3), Vec3(-18.2, 9, 25), Vec3(-24, 9, -89.7), Vec3(-957.8, 3.8, -77.6), Vec3(-170.9, 5.9, 165.1), Vec3(-167.8, 20, 146.9)
        },
        Closed = {
            Vec3(-956.1, 5, -176.71), Vec3(-956.1, 5, -163.1), Vec3(-184.9, 5.9, 161.9), Vec3(-61, 7.8, -317.8), Vec3(-45.8, 7.8, -327.2), Vec3(-83, 7.8, -304.1), Vec3(-26.6, 7.8, -298.5), Vec3(-240.4, 8, -32.5), Vec3(-272.6, 8, -47.9), Vec3(-114.5, 8.5, -99.6), Vec3(-108.2, 8.6, -129), Vec3(-123.6, 8.6, -96.8), Vec3(-120.1, 7.5, -401.8), Vec3(-135.5, 7.5, -369.6), Vec3(-129.2, 7.4, -399), Vec3(-761.7, 7.4, -105.1), Vec3(-793.3, 7.4, -145.5), Vec3(-157, 7.6, -353.2), Vec3(-188.6, 7.6, -393.6), Vec3(-201.4, 9.2, -16.4), Vec3(-169.9, 9.2, 23.9), Vec3(-21.3, 8.9, -65.2), Vec3(-61.8, 8.9, -33.7), Vec3(-251.8, 5.6, 127), Vec3(-284.7, 5.6, 126.9), Vec3(-835.5, 20.4, 119.1), Vec3(-835.5, 33.4, 119.5), Vec3(-835.5, 46.4, 118.5), Vec3(-823.1, 7.4, 92.8), Vec3(-625.9, 20.4, -24.1), Vec3(-625.5, 33.4, -24.1), Vec3(-626.5, 46.4, -24.1), Vec3(-652.2, 7.4, -36.6), Vec3(-985.8, 20.2, -50.2), Vec3(-986.2, 33.2, -50.2), Vec3(-985.2, 46.2, -50.2), Vec3(-959.5, 7.2, -37.7), Vec3(-29.6, 20.1, -504.3), Vec3(-29.6, 33.1, -504.7), Vec3(-29.6, 46.1, -503.7), Vec3(-42, 7, -478), Vec3(-644.1, 4.2, -338.9), Vec3(-184.9, 5.9, 128.9), Vec3(-47.6, 9, 7.6), Vec3(-55.6, 9, -111), Vec3(-994.1, 3.9, -83.4), Vec3(-542.9, -18.9, -105.5), Vec3(-40.4, 9, -120.4), Vec3(-501.7, 5.2, -55.5), Vec3(-997.2, 3.9, -73.5), Vec3(-960.6, 3.8, -81.3), Vec3(-195.9, 20, 149.7), Vec3(-173.6, 5.9, 134.1), Vec3(-44.8, 8.9, 16.7), Vec3(-77.6, 9, -97.3), Vec3(-15.4, 9, 23), Vec3(-21.26, 9, -91.7), Vec3(-960.6, 3.8, -75.6), Vec3(-173.6, 5.9, 167.1), Vec3(-165.9, 20, 149.7)
        }
    },
    Windows = {
        Open = {
            
        },
        Closed = {

        }
    }
} or {
    Doors = {
        Open = {
            Vec3(-173, 4, 177), Vec3(-164, 5, 178), Vec3(-35, 4, 119), Vec3(-25, 4, 120), Vec3(-53, 4, 172), Vec3(-466, 4, 64), Vec3(-438, 4, 64), Vec3(-355, 4, 64), Vec3(-327, 4, 64), Vec3(-411, 4, 64), Vec3(-383, 4, 64), Vec3(-535, 5, 91), Vec3(-534, 5, 82), Vec3(-306, 5, 82), Vec3(-307, 5, 91), Vec3(-62, 4, 171), Vec3(-522, 4, 64), Vec3(-494, 4, 64), Vec3(-491, 4, 110), Vec3(-519, 4, 110), Vec3(-435, 4, 110), Vec3(-463, 4, 110), Vec3(-380, 4, 110), Vec3(-408, 4, 110), Vec3(-352, 4, 110), Vec3(-324, 4, 110)
        },
        Closed = {
            Vec3(-171, 4, 180), Vec3(-166, 4, 180), Vec3(-33, 4, 122), Vec3(-28, 4, 122), Vec3(-56, 4, 174), Vec3(-464, 4, 66), Vec3(-436, 4, 66), Vec3(-353, 4, 66), Vec3(-325, 4, 66), Vec3(-409, 4, 66), Vec3(-381, 4, 66), Vec3(-537, 5, 89), Vec3(-537, 5, 84), Vec3(-309, 5, 84), Vec3(-309, 5, 89), Vec3(-60, 4, 174), Vec3(-520, 4, 66), Vec3(-492, 4, 66), Vec3(-493, 4, 108), Vec3(-521, 4, 108), Vec3(-437, 4, 108), Vec3(-465, 4, 108), Vec3(-382, 4, 108), Vec3(-410, 4, 108), Vec3(-354, 4, 108), Vec3(-326, 4, 108)
        }
    }
}

return DoorData
