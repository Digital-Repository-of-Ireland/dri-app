function ImprovedTextBox(textbox_str){
    this.textbox = $(textbox_str);
    this.last_tb_value;
    this.catch_tb_value();
}

ImprovedTextBox.prototype.catch_tb_value = function(){
    this.last_tb_value = this.textbox.val();
};

ImprovedTextBox.prototype.hide = function(){
    this.textbox.hide();
};

ImprovedTextBox.prototype.show = function(){
    this.textbox.show();
};

ImprovedTextBox.prototype.value = function(){
    return this.textbox.val();
};

ImprovedTextBox.prototype.val = function(text){
    this.textbox.val(text);
};

ImprovedTextBox.prototype.restore_previous_value = function(){
    this.textbox.val(this.last_tb_value);
};

ImprovedTextBox.prototype.add_user_string = function(text){
    //comma followed by spaces, then text then spaces and final comma
    var regex_contains = new RegExp(",\\s*" + text + "\\s*,");
    var regex_start = new RegExp("^\\s*" + text + "\\s*,?\\s*");

    if(!this.textbox.val().match(regex_contains) && !this.textbox.val().match(regex_start)){
        this.textbox.val(text+", "+this.textbox.val());
    }
};
