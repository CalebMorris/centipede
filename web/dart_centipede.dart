import 'dart:html';
import 'dart:math';
import 'dart:async';

/*      
        Centipeed
  Simple game that you collect food and grow until there is no more room.
  End Condition: All body blocks have two adjacent blocks
  Bodysection size = 8px
  Border = 4px
*/

void main() {
  CanvasElement canvas = query("#myCanvas");
  canvas.focus();
  var centipede = new Game(canvas);
  centipede.init();
}

num fpsAverage;

void showFps(num fps) {
  if (fpsAverage == null) {
    fpsAverage = fps;
  }

  fpsAverage = fps * 0.05 + fpsAverage * 0.95;

  query("#notes").text = "${fpsAverage.round().toInt()} fps";
}

class Game {
  CanvasElement canvas;
  
  num renderTime;
  
  num _width;
  num _height;
  
  num speed;
  num cell_size; //4 = 4px x 4px cells
  var max_cells;
  num fill;
  num growth_rate;
  num growth_remaining;
  var body;
  String direction;
  bool game_running;
  Cell head;
  
  var current_food;
  
  Game(this.canvas){
    this.canvas.onKeyDown.listen(key_listener);
    _width = canvas.width;
    _height = canvas.height;
    cell_size = 8;
    speed = 100;
    max_cells = [(_width/cell_size).toInt(),
                 (_height/cell_size).toInt()];
    head = new Cell(_width/cell_size/2, _height/cell_size/2, cell_size);
    body = [head];
    growth_rate = 4;
    growth_remaining = 0;
    switch(new Random().nextInt(4)) {
      case 0:
        direction = "North";
        break;
      case 1:
        direction = "South";
        break;
      case 2:
        direction = "East";
        break;
      default:
        direction = "West";
    }
    get_next_food();
    game_running = true;
  }
  
  void key_listener( e ) {
    switch( e.keyCode ) {
      case 37:
        change_direction("West");
        //print("West");
        break;
      case 38:
        change_direction("North");
        //print("North");
        break;
      case 39:
        change_direction("East");
        //print("East");
        break;
      case 40:
        change_direction("South");
        //print("South");
        break;
    }
  }
  
  void get_next_food() {
    //TODO do check if position in body
    var rnd = new Random(new DateTime.now().millisecondsSinceEpoch);
    num first = rnd.nextInt(max_cells[0]);
    num second = rnd.nextInt(max_cells[1]);
    current_food = new Food(first, second, cell_size);
  }
  
  void init() {
    clear_screen();
    step();
    requestRedraw();
  }
  
  void clear_screen() {
    var context = canvas.context2D;
    context.fillStyle = 'black';
    context.fillRect(0, 0, _width, _height);
  }
  
  void step() {
    //Move along the current direction from the head of the snake
    var next_position = new Cell.nextPosition(head, direction);
    //print("Next: $next_position");
    //print("Body: $body");
    if( next_position.x > max_cells[0] || next_position.y > max_cells[1] ||
        next_position.x < 0 || next_position.y < 0) {
      game_over();
    }
    if( current_food.compareTo(next_position)==0 ) {
      growth_remaining += growth_rate;
      get_next_food();
    }
    if( growth_remaining < 1 ) {
      body.removeLast();
    }
    else {
      growth_remaining--;
    }
    for( var i = 0; i < body.length; ++i ) {
      if( next_position.equal(body[i]) ) {
        game_over();
      }
    }
    body.insert(0,next_position);
    head = body[0];
    if( game_running ) {
     new Timer(new Duration(milliseconds:speed), step);
    }
  }
  
  void game_over() {
    game_running = false;
  }
  
  void change_direction(String direction) {
    this.direction = direction;
  }
  
  void draw(num _) {
    var context = canvas.context2D;
    
    num time = new DateTime.now().millisecondsSinceEpoch;

    if (renderTime != null) {
      showFps((1000 / (time - renderTime)).round());
    }
    
    renderTime = time;
    
    clear_screen();
    current_food.draw(context);
    for( var i = 0; i < body.length; ++i ) {
      body[i].draw(context);
    }
    if( game_running ) {
      requestRedraw();
    }
  }
  
  void requestRedraw() {
    window.requestAnimationFrame(draw);
  }
}

class Cell {
  num x;
  num y;
  num body_size;
  Cell(this.x,this.y,this.body_size) {}
  Cell.nextPosition(Cell current,String direction) {
    this.body_size = current.body_size;
    switch(direction) {
      case 'North':
        this.x = current.x;
        this.y = current.y-1;
        break;
      case 'South':
        this.x = current.x;
        this.y = current.y+1;
        break;
      case 'East':
        this.x = current.x+1;
        this.y = current.y;
        break;
      case 'West':
        this.x = current.x-1;
        this.y = current.y;
        break;
    }
  }
  void draw(CanvasRenderingContext2D context) {
    if( x+body_size < 0 || x-body_size >= context.canvas.width ) {
      return;
    }
    if( y+body_size < 0 || y-body_size >= context.canvas.height ) {
      return;
    }
    context.clearRect(x*body_size, y*body_size, body_size, body_size);
  }
  bool equal(Cell other) {
    if( this.x == other.x && this.y == other.y ) {
      return true;
    }
    return false;
  }
  bool equalFromCoord(num x, num y) {
    if( this.x == x && this.y == y ) {
      return true;
    }
    return false;
  }
  String toString() {
    return "(" +x.toString()+ "," +y.toString()+ ")";
  }
}

class Food {
  num x;
  num y;
  num body_size;
  Food(this.x,this.y,this.body_size) {}
  int compareTo(Cell cell) {
    if( this.x == cell.x && this.y == cell.y ) {
      return 0;
    }
    else {
      return -1;
    }
  }
  void draw(CanvasRenderingContext2D context) {
    if( x+body_size < 0 || x-body_size >= context.canvas.width ) {
      return;
    }
    if( y+body_size < 0 || y-body_size >= context.canvas.height ) {
      return;
    }
    context.save();
    context.beginPath();
    context.arc(x*body_size+body_size/2,y*body_size+body_size/2,body_size/2,0,PI*2);
    context.closePath();
    context.clip();
    context.clearRect(x*body_size, y*body_size, body_size, body_size);
    context.restore();
  }
}

/*
function init_var() {
  c.onmousedown = myDown;
  c.onmouseup = myUp;

  dir_queue = false;

  body = [[(c.width/2),(c.height/2)]];
  get_next_food();
}

<script>
var body; var grow; var direction; var c; var ctx; var tmp;
var tmp2; var new_position; var tail; var game_running; var next_food;
var mx, my; var show_menu; var active_menu;

var main; var pause; var game_over;

var dir_queue;

function init() {
  init_var();
  addEventHandlers();
  game_loop();
  //load_menus();
  start_game_timer();
}

function key_down(e) {
  switch( e.keyCode ) {
    case 37:
      change_direction("West");
      break;
    case 38:
      change_direction("South");
      break;
    case 39:
      change_direction("East");
      break;
    case 40:
      change_direction("North");
      break;
  }
}

function getMouse(e) {
  var element = c;
  var offsetX = 0, offsetY = 0;

  if (element.offsetParent) {
    do {
      offsetX += element.offsetLeft;
      offsetY += element.offsetTop;
    } while ((element = element.offsetParent));
  }

  // Add padding and border style widths to offset
  //offsetX += stylePaddingLeft;
  //offsetY += stylePaddingTop;

  //offsetX += styleBorderLeft;
  //offsetY += styleBorderTop;

  mx = e.pageX - offsetX;
  my = e.pageY - offsetY
}

function step() {
  // Move in the current direction
  switch(direction) {
    case "North":
      new_position = [[body[0][0],body[0][1]+8]];
      break;
    case "South":
      new_position = [[body[0][0],body[0][1]-8]];
      break;
    case "East":
      new_position = [[body[0][0]+8,body[0][1]]];
      break;
    case "West":
      new_position = [[body[0][0]-8,body[0][1]]];
      break;
  }
  //console.log(new_position);
  //console.log(body);
  if(past_edge(new_position[0])) {
    game_over();
  };
  if ( new_position[0][0] == next_food[0] &&
     new_position[0][1] == next_food[1] ) {
    grow+=100;
    get_next_food();
  };
  if (grow<1) {
    body.pop();
  }
  else {
    grow--;
  };
  for (var i = body.length - 1; i >= 0; i--) {
    if( new_position[0][0]==body[i][0] &&
      new_position[0][1]==body[i][1] ) {
      //TODO self-collision detection
      console.log("collision");
      game_over();
    }
  };
  body = new_position.concat(body);
  dir_queue = false;
}

function draw_success() {
  ctx.clearRect(c.width/4,c.height/5,c.width/2,c.height/7);
  //ctx.clearRect(0,0,c.width,c.height);
  ctx.font = "30px arial";
  ctx.fillText("Congradulations",c.width/4,c.height/5+27,c.width/2);
  ctx.fillText("You Won",c.width/4+40,c.height/5+55,c.width/2);
}

function draw_failure() {
  ctx.clearRect(c.width/4,c.height/5,c.width/2,c.height/7);
  //ctx.clearRect(0,0,c.width,c.height);
  ctx.font = "30px arial";
  ctx.fillText("Game Over",c.width/4+20,c.height/5+40,c.width/2);
}

function change_direction(new_dir) {
  if( !dir_queue ) {
    if( (direction == "North" || direction == "South") &&
      (new_dir == "East" || new_dir == "West") ) {
      direction = new_dir;
      dir_queue = true;
    }
    if( (direction == "East" || direction == "West") &&
      (new_dir == "North" || new_dir == "South") ) {
      direction = new_dir;
      dir_queue = true;
    }
  };
}

function game_over() {
  // Game over menu
  game_running = false;
  
  if (has_won()) {
    // Display success
    window.setTimeout(draw_success, 100);
  } 
  else {
    // Display failure
    window.setTimeout(draw_failure, 100);
  };
}

function has_won() {
  // Check if the person won or lost
  if (body.length < 2500) {return false;};
  return true;
}

function game_loop() {
  step();
  draw();
}

function start_game_timer() {
  function timer()
    {
      if(game_running)
      {
        game_loop();
        window.setTimeout(timer, 100);
      }
    }
  if(game_running){
    window.setTimeout(timer, 15);
  };
}

function addEventHandlers() {
  window.addEventListener( "keypress", key_down, true);
}

</script>
</head>
<body>

<div id="container" style="border:1px solid; width:402px; height:402px;">     
  <canvas id="myCanvas" width="402" height="402">Oh dear, your browser dosen't support HTML5! Tell you what, why don't you upgrade to a decent browser - you won't regret it!
  </canvas>  
</div>

</body>
</html>
*/