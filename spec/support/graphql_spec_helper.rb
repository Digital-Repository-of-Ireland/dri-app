module GraphqlSpecHelper
  def get_graphql_results(filter_func: '', filter_arg: 'filter_test')
    filter_args = { filter: { "#{filter_func}": filter_arg } }
    subject.class.call(nil, filter_args, nil)
  end
end
