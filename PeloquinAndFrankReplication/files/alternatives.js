function chooseRandom(list) {
    return list[Math.floor(Math.random() * list.length)];
}

function shuffle(v) { // non-destructive.
    newarray = v.slice(0);
    for (var j, x, i = newarray.length; i; j = parseInt(Math.random() * i), x = newarray[--i], newarray[i] = newarray[j], newarray[j] = x);
    return newarray;
}

function getRandom(arr,n) {
  console.log(arr,n)
  var newArr = shuffle(arr);
  var rand = newArr.slice(0,n)
  return(rand)
}

var stimuliList = [
  "liked",
  "loved",
  "good",
  "excellent",
  "memorable",
  "unforgetable",
  "palatable",
  "delicious",
];
//"some" and "all" are in the og paper, but don't make sense in context.
//context also doesn't make sense for love, so span is going to have to be
//  more specific predicates for each of the targets

wordlist = shuffle(stimuliList)

var data = {};

data.wordlist = wordlist

$(document).ready(function() {
    showSlide("intro");
    $('#gotoInstructions').click(function() {
        document.body.scrollTop = document.documentElement.scrollTop = 0;
        showSlide('instructions');
    });
    $('#gotoCheck').click(function(){
        document.body.scrollTop = document.documentElement.scrollTop = 0;
        showSlide('audioCheck');
    });

    document.getElementById('sampleAudio').src = "http://stanford.edu/~sunwooj/experiments/dec1/stimuli/sample.wav";

    $('#startbutton').click(function() {
        var nat = document.getElementById("native").checked;
        var spe = true;
        if (nat == true && spe == true) {
            document.body.scrollTop = document.documentElement.scrollTop = 0;
            var word = wordlist.shift();
            document.getElementById('scalar_target1').innerHTML = word;
            document.getElementById('scalar_target2').innerHTML = word;
            showSlide('freeResponse');
        }
        else {
            checkboxwarning = "Please check the box to confirm that you meet the necessary requirements, in order to proceed to the experiment.";
            $("#checkboxWarning").html(checkboxwarning);
        }
    });

    $('#veributton').click(function() {
        var response = document.getElementById("speakerPerception").value;
        if (response == '') {
            $("#veriWarning").html("Please respond to the question.")
        } else {
            data.response = response;
            document.body.scrollTop = document.documentElement.scrollTop = 0;
            showSlide('language');
        }
    });

    $('#lgsubmit').click(function() {
        var seclang = $('#otherlangForm').serialize();
        var gender = $('#genderForm').serialize();
        var age = $('#ageForm').serialize();
        var race = $('#ethnicityForm').serialize();
        var region = $('#dialect').val();
        region = region.replace (/,/g, "");
        var region_com = $('#lang_com').val();
        region_com = region_com.replace (/,/g, "");

        data.seclang = seclang;
        data.gender = gender;
        data.age = age;
        data.race = race;
        data.region = region;
        data.regionComments = region_com;

        showSlide('finish');
        setTimeout(function() { turk.submit(data)}, 1000);
    });
});

function showSlide (slideName) {
    $('.slide').hide();
    $('#' + slideName).show();
}
