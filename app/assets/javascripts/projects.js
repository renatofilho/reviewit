window.projects = function() {
    var tags = $('#project_owners, #project_members');
    tags.each(function(index) {
      var value = tags[index]
      var field = value.dataset.field
      var users = value.dataset.users.split('|');
      var myself = value.dataset.myself;

      var before_add = function(event, ui) {
          return users.indexOf(ui.tagLabel) !== -1;
      };

      var before_remove = function(event, ui) {
          var its_me = ui.tagLabel === myself;
          if (its_me)
              alert('You need to participate on your own project.');
          return !its_me;
      };

      $(tags[index]).tagit({
                fieldName: 'project['+field+'][]',
                availableTags: users,
                autocomplete: {
                    delay: 0,
                    minLength: 1
                },
                allowDuplicates: false,
                removeConfirmation: true,
                beforeTagAdded: before_add,
                beforeTagRemoved: before_remove,
                placeholderText: 'Type the ' + field + ' names'
            });
  })

};
