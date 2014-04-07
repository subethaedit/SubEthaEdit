<?Lassoscript 
	if(!(lasso_tagexists('xs_isError')));
		define_tag('isError',	
			-namespace='xs_',
			-priority='replace');
			// ----------------------------------------------------
			if((Error_CurrentError(-ErrorCode)));
				$gv_error += (Error_CurrentError) + '<br />';
			else((File_CurrentError(-ErrorCode)));
				$gv_error += (File_CurrentError) + '<br />';
			/if;
			// ----------------------------------------------------
		/define_tag;
	/if;


?>