function starColor(n) {
  console.log(n)
  var i;
  for (i = 1; i < 6; i++){
    document.getElementById('star'+i.toString()).classList.remove('checked')
  }
  for (i = 1; i <= n; i++){
    document.getElementById('star'+i.toString()).classList.add('checked')
  }
}
/*
document.getElementById('star1').onclick = starColor(1);
document.getElementById('star2').onclick = starColor(2);
document.getElementById('star3').onclick = starColor(3);
document.getElementById('star4').onclick = starColor(4);
document.getElementById('star5').onclick = starColor(5);
*/
