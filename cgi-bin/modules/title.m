sub title {
	($markup) = @_ if @_;
	$markup=~s/<!--xg_var:title-->/something/gie;
	return $markup;
};